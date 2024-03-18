ARG RUST_VERSION=1.75.0

FROM rust:${RUST_VERSION} AS builder
WORKDIR /app
COPY . .
RUN \
  --mount=type=cache,target=/app/target/ \
  --mount=type=cache,target=/usr/local/cargo/registry/ \
  --mount=type=ssh \
  mkdir -p /root/.cargo/bin/ && \
  rustup target add wasm32-unknown-unknown && \
  cargo install flawless --version 1.0.0-alpha.16 --features="cargo-flw"

EXPOSE 8080/tcp
EXPOSE 27288/tcp
ENTRYPOINT ["/root/.cargo/bin/flawless", "up"]


FROM builder
ENTRYPOINT ["cargo", "flw", "run", "risk-central", "--input", "{\"vat_code\":\"01234567890\",\"ndg\":\"333444\"}"]
