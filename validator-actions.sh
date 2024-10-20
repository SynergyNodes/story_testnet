#!/bin/bash

# Function to display the menu
display_menu() {
    echo "Select an Option"
    echo "1. Stop Story Node"
    echo "2. Stop Geth Node"
    echo "3. Stop Both Nodes"
    echo "4. Restart Story Node"
    echo "5. Restart Geth Node"
    echo "6. Restart Both Nodes"
    echo "7. Download & Extract Pruned Snapshot"
    echo "8. Download & Extract Archive Snapshot"
    echo "9. Add / Update Live Peers"
    echo "10. Donwload & replace Addrbook.json"
    echo "11. Download & replace Genesis.json"
    echo "12. Check Sync Status"
    echo "13. Get Node's Voting Power"
    echo "14. Select an Option"
    echo "15. Start Story Node"
    echo "16. Start Geth Node"
    echo "17. Start Both Nodes"    
    echo "18. Exit"
}

# Function to download pruned snapshot
pruned_snaphot() {
    echo ""
    echo ""

    # Stop the services
    sudo service story-geth stop
    sudo service story stop

    # Wait for 30 seconds
    sleep 30 

    echo "Downloading and restoring Story snapshot ..."
    cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup
    rm -rf $HOME/.story/story/data

    # Download the snapshot for Story
    SNAPSHOT_STORY=$(curl -s "https://www.synergynodes.com/snapshots.php?chain=story_testnet_story")
    curl -L $SNAPSHOT_STORY | tar -Ilz4 -xf - -C $HOME/.story/story
    mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json

    echo ""
    echo ""
    echo "Downloading and restoring Story-Geth snapshot ..."
    # Download the snapshot for Geth
    SNAPSHOT_GETH=$(curl -s "https://www.synergynodes.com/snapshots.php?chain=story_testnet_geth")
    curl -L $SNAPSHOT_GETH | tar -Ilz4 -xf - -C $HOME/.story/geth/iliad/geth

    # Start the services
    sudo service story-geth start
    sudo service story start  
}

# Function to download archive snapshot
archive_snapshot() {
    echo ""
    echo ""

    # Stop the services
    sudo service story-geth stop
    sudo service story stop

    # Wait for 30 seconds
    sleep 30 

    echo "Downloading and restoring Story snapshot ..."
    cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup
    rm -rf $HOME/.story/story/data

    # Download the snapshot for Story
    SNAPSHOT_STORY=$(curl -s "https://www.synergynodes.com/snapshots.php?chain=story_archive_story")
    curl -L $SNAPSHOT_STORY | tar -Ilz4 -xf - -C $HOME/.story/story
    mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json

    echo ""
    echo ""
    echo "Downloading and restoring Story-Geth snapshot ..."
    # Download the snapshot for Geth
    SNAPSHOT_GETH=$(curl -s "https://www.synergynodes.com/snapshots.php?chain=story_archive_geth")
    curl -L $SNAPSHOT_GETH | tar -Ilz4 -xf - -C $HOME/.story/geth/iliad/geth

    # Start the services
    sudo service story-geth start
    sudo service story start
}

stop_story() {
    sudo service story stop
    echo "Done!"
}

stop_geth() {
    sudo service story-geth stop
    echo "Done!"
}

stop_both() {
    sudo service story stop
    sudo service story-geth stop
    echo "Done!"
}

restart_story() {
    sudo service story restart
    echo "Done!"
}

restart_geth() {
    sudo service story-geth restart
    echo "Done!"
}

restart_both() {
    sudo service story restart
    sudo service story-geth restart
    echo "Done!"
}

update_peers() {
    echo ""
    echo ""
    echo "Adding peers to config.toml file ..."

    PEERS=$(curl -sS https://story-testnet-rpc.synergynodes.com/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}' | paste -sd, -)
    echo $PEERS
    sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.story/story/config/config.toml
    
    echo ""
    echo "Done!"       
}

update_addrbook() {
    echo "Downloading & replacing Addrbook file ..."
    curl -Ls https://support.synergynodes.com/addrbook/story_testnet/addrbook.json > $HOME/.story/story/config/addrbook.json
    echo ""
    echo "Done!"
}

update_genesis() {
    echo "Downloading & replacing Genesis file ..."
    curl -Ls https://support.synergynodes.com/genesis/story_testnet/genesis.json > $HOME/.story/story/config/genesis.json
    echo ""
    echo "Done!"
}

check_sync() {
    curl -s http://localhost:26657/status | jq -r '.result.sync_info.catching_up'
}

get_vp() {
    curl -s http://localhost:26657/status | jq -r '.result.validator_info.voting_power'
}

start_story() {
    sudo service story start
    echo "Done!"
}

start_geth() {
    sudo service story-geth start
    echo "Done!"
}

start_both() {
    sudo service story start
    sudo service story-geth start
    echo "Done!"
}




# Main loop
while true; do
    display_menu
    read -p "Enter your choice (1-18): " choice

    case $choice in
        1)
            stop_story
            ;;
        2)
            stop_geth
            ;;
        3)
            stop_both
            ;;
        4)
            restart_story
            ;;
        5)
            restart_geth
            ;;
        6)
            restart_both
            ;;
        7)
            pruned_snaphot
            ;;
        8)
            archive_snaphot
            ;;
        9)
            update_peers
            ;;
        10)
            update_addrbook
            ;;
        11)
            update_genesis
            ;;
        12)
            check_sync
            ;;
        13)
            get_vp
            ;;
        14)
            start_story
            ;;
        15)
            start_geth
            ;;
        16)
            start_both
            ;;
        17)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please enter from 1 to 17."
            ;;
    esac
done
