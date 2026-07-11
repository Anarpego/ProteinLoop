FROM ubuntu:24.04

ARG LLAMA_CPP_RELEASE=b9957
ARG TARGETARCH
ARG LLAMA_CPP_SHA256_AMD64=731a74cbb99783e8d4dc3a530e1a94fae3fa0960a57574b62926efde694dba94
ARG LLAMA_CPP_SHA256_ARM64=dc9e28f4a6e7c5bc9b22bd3669043c23cfe8f5af6428eada7f47de10e6923f34

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl libgomp1 \
  && rm -rf /var/lib/apt/lists/* \
  && case "${TARGETARCH}" in \
    amd64) LLAMA_ARCHIVE="ubuntu-x64"; LLAMA_SHA256="${LLAMA_CPP_SHA256_AMD64}" ;; \
    arm64) LLAMA_ARCHIVE="ubuntu-arm64"; LLAMA_SHA256="${LLAMA_CPP_SHA256_ARM64}" ;; \
    *) echo "unsupported target architecture: ${TARGETARCH}" >&2; exit 1 ;; \
  esac \
  && curl -fsSL \
    "https://github.com/ggml-org/llama.cpp/releases/download/${LLAMA_CPP_RELEASE}/llama-${LLAMA_CPP_RELEASE}-bin-${LLAMA_ARCHIVE}.tar.gz" \
    -o /tmp/llama.tar.gz \
  && echo "${LLAMA_SHA256}  /tmp/llama.tar.gz" | sha256sum -c - \
  && mkdir -p /opt/llama \
  && tar -xzf /tmp/llama.tar.gz --strip-components=1 -C /opt/llama \
  && rm /tmp/llama.tar.gz \
  && groupadd --system llama \
  && useradd --system --gid llama --home-dir /home/llama --create-home llama \
  && chown -R llama:llama /opt/llama /home/llama

ENV LD_LIBRARY_PATH=/opt/llama

WORKDIR /opt/llama
USER llama

EXPOSE 8001

ENTRYPOINT ["/opt/llama/llama-server"]
