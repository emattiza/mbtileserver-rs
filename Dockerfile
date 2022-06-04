FROM rust:1.60 AS chef
# We only pay the installation cost once,
# it will be cached from the second build onwards
RUN cargo install cargo-chef
WORKDIR app

FROM chef AS planner
COPY . .
RUN cargo chef prepare  --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .
RUN cargo build --release

# We do not need the Rust toolchain to run the binary!
FROM debian:bullseye-slim AS runtime
WORKDIR app
USER root
RUN apt update && apt install -yq libsqlite3-0
COPY --from=builder /app/target/release/mbtileserver /usr/local/bin
CMD ["/usr/local/bin/mbtileserver", "-d", "/tiles"]

# FROM rust:1.60
#
# WORKDIR /usr/src/mbtileserver
# COPY . .
#
# RUN mkdir /tiles
#
# RUN cargo install --path .
#
# CMD ["mbtileserver -d /tiles"]
