#!/bin/bash

# Function to display the menu
display_menu() {
    echo "Please select the type of Snapshot to download:"
    echo "1. Pruned Snapshot"
    echo "2. Archive Snapshot"
    echo "3. Exit"
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

# Main loop
while true; do
    display_menu
    read -p "Enter your choice (1-3): " choice

    case $choice in
        1)
            pruned_snaphot
            ;;
        2)
            archive_snapshot
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please enter 1, 2, or 3."
            ;;
    esac
done
