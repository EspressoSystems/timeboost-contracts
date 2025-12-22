//! Helper functions to build Ethereum [providers](https://docs.rs/alloy/latest/alloy/providers/trait.Provider.html)
//! Partial Credit: <https://github.com/EspressoSystems/espresso-network/tree/main/contracts/rust/deployer>

use std::{ops::Deref, time::Duration};

use alloy::{
    eips::BlockNumberOrTag,
    network::{Ethereum, EthereumWallet},
    primitives::Address,
    providers::{Provider, ProviderBuilder},
    providers::{
        RootProvider,
        fillers::{FillProvider, JoinFill, WalletFiller},
        layers::AnvilProvider,
        utils::JoinedRecommendedFillers,
    },
    rpc::types::{Filter, Log},
    signers::local::{LocalSignerError, MnemonicBuilder, PrivateKeySigner, coins_bip39::English},
    sol_types::SolEvent,
    transports::{http::reqwest::Url, ws::WsConnect},
};
use futures::{Stream, StreamExt};
use tracing::error;

pub type HttpProviderWithWallet = FillProvider<
    JoinFill<JoinedRecommendedFillers, WalletFiller<EthereumWallet>>,
    RootProvider,
    Ethereum,
>;

/// Provider connected to blockchain URL with read only access
pub type HttpProvider = FillProvider<JoinedRecommendedFillers, RootProvider, Ethereum>;

/// Similar to `HttpProviderWithWallet` except the network being the Anvil test blockchain
pub type TestProviderWithWallet = FillProvider<
    JoinFill<JoinedRecommendedFillers, WalletFiller<EthereumWallet>>,
    AnvilProvider<RootProvider>,
    Ethereum,
>;

/// Build a local signer from wallet mnemonic and account index
pub fn build_signer(
    mnemonic: String,
    account_index: u32,
) -> Result<PrivateKeySigner, LocalSignerError> {
    MnemonicBuilder::<English>::default()
        .phrase(mnemonic)
        .index(account_index)?
        .build()
}

/// a handy thin wrapper around wallet builder and provider builder that directly
/// returns an instantiated `Provider` with default fillers with wallet, ready to send tx
pub fn build_provider(
    mnemonic: String,
    account_index: u32,
    url: Url,
) -> Result<HttpProviderWithWallet, LocalSignerError> {
    let signer = build_signer(mnemonic, account_index)?;
    let wallet = EthereumWallet::from(signer);
    Ok(ProviderBuilder::new().wallet(wallet).connect_http(url))
}

#[derive(Debug, Clone)]
#[non_exhaustive]
pub struct PubSubProviderConfig {
    pub url: Url,
    pub max_retries: u32,
    pub retry_interval: Duration,
}

impl PubSubProviderConfig {
    pub fn new(url: Url) -> Self {
        Self {
            url,
            max_retries: 12,
            retry_interval: Duration::from_secs(5),
        }
    }
}

/// A PubSub service (with backend handle), disconnect on drop.
pub struct PubSubProvider {
    inner: HttpProvider,
}

impl Deref for PubSubProvider {
    type Target = HttpProvider;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl PubSubProvider {
    pub async fn new(cfg: PubSubProviderConfig) -> anyhow::Result<Self> {
        let ws = WsConnect::new(cfg.url)
            .with_max_retries(cfg.max_retries)
            .with_retry_interval(cfg.retry_interval);
        let provider = ProviderBuilder::new()
            .connect_pubsub_with(ws)
            .await
            .map_err(|err| {
                error!(?err, "event pubsub failed to start");
                err
            })?;
        Ok(Self { inner: provider })
    }

    /// create an event stream of event type `E`, subscribing since `from_block` on `contract`
    pub async fn event_stream<E: SolEvent>(
        &self,
        contract: Address,
        from_block: BlockNumberOrTag,
    ) -> anyhow::Result<impl Stream<Item = Log<E>> + Send + use<E>> {
        let filter = Filter::new()
            .address(contract)
            .event(E::SIGNATURE)
            .from_block(from_block);

        let events = self
            .subscribe_logs(&filter)
            .await
            .map_err(|err| {
                error!(?err, "pubsub subscription failed");
                err
            })?
            .into_stream();

        let validated = events.filter_map(|log| async move {
            match log.log_decode_validate::<E>() {
                Ok(event) => Some(event),
                Err(err) => {
                    error!(%err, "failed to parse `CommitteeCreated` event log");
                    None
                }
            }
        });

        Ok(validated)
    }
}
