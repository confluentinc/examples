// https://github.com/fede1024/rust-rdkafka/issues/125
fn main() {
    println!("cargo:rustc-link-lib=zstd");
}
