build:
    forge build

gen-rust-bindings:
    forge bind \
        --contracts src \
        --out out \
        --module \
        --overwrite \
        --bindings-path rust/timeboost-contract/src/bindings
    (cd rust/timeboost-contract && cargo build)
