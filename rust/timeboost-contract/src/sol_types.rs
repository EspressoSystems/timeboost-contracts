//! Solidity types for contract interaction

pub use crate::bindings::{
    erc1967_proxy::ERC1967Proxy,
    key_manager::KeyManager,
    key_manager::KeyManager::{Committee as CommitteeSol, CommitteeMember as CommitteeMemberSol},
};

impl CommitteeMemberSol {
    #[cfg(test)]
    pub fn random() -> Self {
        use alloy::primitives::Bytes;
        use rand::prelude::*;

        let mut rng = rand::rng();
        CommitteeMemberSol {
            sigKey: Bytes::from(rng.random::<[u8; 32]>()),
            dhKey: Bytes::from(rng.random::<[u8; 32]>()),
            dkgKey: Bytes::from(rng.random::<[u8; 32]>()),
            networkAddress: format!("127.0.0.1:{}", rng.random::<u16>()),
            batchPosterAddress: format!("127.0.0.1:{}", rng.random::<u16>()),
            sigKeyAddress: alloy::primitives::Address::default(),
        }
    }
}
