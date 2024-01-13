ARG RUST_VERSION=1.75.0

FROM rust:${RUST_VERSION} AS builder
WORKDIR /app
COPY . .
RUN \
  --mount=type=cache,target=/app/target/ \
  --mount=type=cache,target=/usr/local/cargo/registry/ \
  --mount=type=ssh \
  rustup target add wasm32-unknown-unknown && \
  cargo build --release --target=wasm32-unknown-unknown && \
  cargo build --release && \
  cp ./target/wasm32-unknown-unknown/release/librischialess.rlib /rischialess


FROM debian:bookworm-slim AS final
RUN adduser \
  --disabled-password \
  --gecos "" \
  --home "/nonexistent" \
  --shell "/sbin/nologin" \
  --no-create-home \
  --uid "10001" \
  appuser
COPY --from=builder /rischialess /usr/local/bin
RUN chown appuser /usr/local/bin/rischialess
#COPY --from=builder /app/config /opt/rischialess/config
RUN #chown -R appuser /opt/rischialess
USER appuser
ENV RUST_LOG="rischialess=debug,info"
WORKDIR /opt/rischialess
ENTRYPOINT ["rischialess"]
EXPOSE 8080/tcp