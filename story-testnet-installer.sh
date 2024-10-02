#!/bin/bash

check_sudo() {
    if sudo -n true 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

run_commands() {
echo ""
echo ""
echo "Running system updates..."
cd $HOME
sudo apt -q update
sudo apt -qy install wget git make gcc curl jq lz4 unzip build-essential
sudo apt -qy upgrade
cd $HOME

echo ""
echo ""
echo "Installing go1.23.5..."
curl https://dl.google.com/go/go1.23.5.linux-amd64.tar.gz | sudo tar -C /usr/local -zxvf -

echo ""
echo ""
echo "Updating environment variables..."

cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF

echo ""
echo ""
echo "Sourcing the updated profile..."
source $HOME/.profile


echo ""
echo ""
echo "Downloading Story and Story-Geth binaries..."
mkdir -p $HOME/go/bin/

wget https://support.synergynodes.com/misc/story_testnet/story
wget https://support.synergynodes.com/misc/story_testnet/story-geth
mv story $HOME/go/bin/
mv story-geth $HOME/go/bin/
mkdir -p $HOME/.story/story
mkdir -p $HOME/.story/geth/iliad/geth

echo ""
echo ""
echo "Installing the Node..."

echo ""
echo ""
read -p "Enter Moniker Name: " moniker_name
echo "You entered: $moniker_name"

story init --moniker $moniker_name --network iliad

echo ""
echo ""
echo "Downloading Genesis and Addrbook files ..."

curl -Ls https://support.synergynodes.com/genesis/story_testnet/genesis.json > $HOME/.story/story/config/genesis.json
curl -Ls https://support.synergynodes.com/addrbook/story_testnet/addrbook.json > $HOME/.story/story/config/addrbook.json


echo ""
echo ""
echo "Adding peers to config.toml file ..."

PEERS=$(curl -sS https://story-testnet-rpc.synergynodes.com/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}' | paste -sd, -)
echo $PEERS
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.story/story/config/config.toml

echo ""
echo ""
echo "Downloading and restoring Story snapshot ..."
cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup
rm -rf $HOME/.story/story/data

# Download the snapshot for Story
$snapshot_story=$(curl -s "https://www.synergynodes.com/snapshots.php?chain=story_testnet_story")
curl -L $$snapshot_story | tar -Ilz4 -xf - -C $HOME/.story/story
mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json

echo ""
echo ""
echo "Downloading and restoring Story-Geth snapshot ..."
# Download the snapshot for Geth
$snapshot_geth=$(curl -s "https://www.synergynodes.com/snapshots.php?chain=story_testnet_geth")
curl -L $snapshot_geth | tar -Ilz4 -xf - -C $HOME/.story/geth/iliad/geth


echo ""
echo ""
echo "Creating Service files for Story-Geth and Story..."
# Create Story Service
sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Service
After=network.target

[Service]
User=$USER
Group=$USER
WorkingDirectory=$HOME/.story/story
ExecStart=$HOME/go/bin/story run

LimitNOFILE=65535
KillMode=process
KillSignal=SIGINT
TimeoutStopSec=90
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF


# Create Geth Service
sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story-Geth daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/story-geth --iliad --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

# Enable both story-geth and story services
sudo systemctl daemon-reload
sudo systemctl enable story-geth
sudo systemctl enable story

echo ""
echo ""
echo "Staring the nodes ..."

# Start the services
sudo service story-geth start
sudo service story start

echo ""
echo ""
echo "Checking Story-Geth service status..."
sudo systemctl status story-geth --no-pager -l
echo "Checking Story service status..."
sudo systemctl status story --no-pager -l

echo ""
echo ""
echo "Checking Story-Geth Logs..."
sudo journalctl -u story-geth -n 100 -o cat

echo ""
echo ""
echo "Checking Story Logs..."
sudo journalctl -u story -n 100 -o cat

echo ""
echo ""
echo "Checking sync status ..."
curl -s localhost:26657/status | jq

echo ""
echo ""
echo "Installation and setup complete!"

echo ""
echo ""
echo "Check the status of the nodes using the following commands ..."
echo "sudo journalctl -fu story-geth"
echo "sudo journalctl -fu story"

}


if check_sudo; then
    echo "No sudo password needed. Running updates."
    run_commands
else
    echo "Sudo password required. Please enter your password."
    sudo -v
    if [ $? -eq 0 ]; then
        run_commands
    else
        echo "Failed to authenticate. Exiting."
        exit 1
    fi
fi
