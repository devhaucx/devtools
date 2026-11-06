FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Cai dat cac goi co ban va thu vien runtime cho .NET / Azure Pipelines Agent
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    git \
    iputils-ping \
    libcurl4 \
    libicu70 \
    libunwind8 \
    netcat \
    zip \
    unzip \
    tar \
  && rm -rf /var/lib/apt/lists/*

# 2. Cai dat Docker CLI tinh (Static Binary - nhe, gon, khong can them repo apt)
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.9.tgz | tar -xz -C /tmp && \
    mv /tmp/docker/docker /usr/local/bin/docker && \
    chmod +x /usr/local/bin/docker && \
    rm -rf /tmp/docker

# 3. Cai dat kubectl va Helm 3 cho cac buoc Deploy Kubernetes / Helm
RUN curl -fsSL "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    curl -fsSL "https://get.helm.sh/helm-v3.15.4-linux-amd64.tar.gz" | tar -xz -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    rm -rf /tmp/linux-amd64

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x ./start.sh

CMD ["./start.sh"]
