build:
    forge build

gen-rust-bindings:
    forge bind \
        --contracts src \
        --out out \
        --module \
        --bindings-path rust/timeboost-contract/src/bindings
