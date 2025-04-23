FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y && \
apt-get install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool unzip -y

ENV HOME=/app \
NODENAME="Stake Shark" \
ARKEO_CHAIN_ID="arkeo-main-v1" \
GO_VER="1.22.3" \
WALLET="wallet" \
PATH="/usr/local/go/bin:/app/go/bin:${PATH}" \
DAEMON_NAME=arkeod \
DAEMON_HOME=/app/.arkeo \
DAEMON_ALLOW_DOWNLOAD_BINARIES=false \
DAEMON_RESTART_AFTER_UPGRADE=true

WORKDIR /app

RUN wget "https://golang.org/dl/go$GO_VER.linux-amd64.tar.gz" && \
tar -C /usr/local -xzf "go$GO_VER.linux-amd64.tar.gz" && \
rm "go$GO_VER.linux-amd64.tar.gz" && \
mkdir -p go/bin

RUN curl -L https://github.com/arkeonetwork/arkeo/releases/download/v1.0.11/arkeod_1.0.11_linux_amd64.zip -o arkeo.zip && \
unzip arkeod.zip && \ 
rm arkeo.zip && \
mkdir -p /app/arkeo/bin /app/.arkeo/cosmovisor/upgrades /app/.arkeo/cosmovisor/genesis/bin && \
mv /app/arkeod /app/.arkeo/cosmovisor/genesis/bin/arkeod

RUN go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

RUN arkeod init "Stake Shark" --chain-id=arkeo-main-v1

RUN wget -O $HOME/.arkeo/config/genesis.json "https://server-1.stavr.tech/Mainnet/Arkeo/genesis.json" && \
wget -O $HOME/.arkeo/config/addrbook.json "https://server-1.stavr.tech/Mainnet/Arkeo/addrbook.json"

RUN sed -i.bak -e "s/^external_address *=.*/external_address = \"$(wget -qO- eth0.me):26656\"/" $HOME/.arkeo/config/config.toml && \
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.001uarkeo\"|" $HOME/.arkeo/config/app.toml && \
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 40/g' $HOME/.arkeo/config/config.toml && \
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 10/g' $HOME/.arkeo/config/config.toml && \
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.arkeo/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"1000\"/" $HOME/.arkeo/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.arkeo/config/app.toml && \
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.arkeo/config/config.toml && \
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.arkeo/config/config.toml && \
sed -i "s/snapshot-interval *=.*/snapshot-interval = 0/g" $HOME/.arkeo/config/app.toml

RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'sleep 10000' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
