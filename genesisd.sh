#!/bin/bash
cat << "EOF"

  /$$$$$$                                          /$$                 /$$         /$$       
 /$$__  $$                                        |__/                | $$       /$$$$       
| $$  \__/  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$ /$$  /$$$$$$$      | $$      |_  $$       
| $$ /$$$$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/| $$ /$$_____/      | $$        | $$       
| $$|_  $$| $$$$$$$$| $$  \ $$| $$$$$$$$|  $$$$$$ | $$|  $$$$$$       | $$        | $$       
| $$  \ $$| $$_____/| $$  | $$| $$_____/ \____  $$| $$ \____  $$      | $$        | $$       
|  $$$$$$/|  $$$$$$$| $$  | $$|  $$$$$$$ /$$$$$$$/| $$ /$$$$$$$/      | $$$$$$$$ /$$$$$$     
 \______/  \_______/|__/  |__/ \_______/|_______/ |__/|_______/       |________/|______/     
                                                                                             
Welcome to the decentralized blockchain Renaissance, above money & beyond cryptocurrency!
This script upgrades genesis_29-2 (evmos) to genesis_29-2 (cronos) running under root user.
GENESIS L1 is a highly experimental decentralized project, provided AS IS, with NO WARRANTY.
GENESIS L1 IS A NON COMMERCIAL OPEN DECENTRALIZED BLOCKCHAIN PROJECT RELATED TO SCIENCE AND ART
THIS IS AN UPGRADE TO COSMOS SDK V0.46.15 BASED ON CRONOS RELEASE SOURCE CODE, THANK YOU!
  
  Mainnet EVM chain ID: 29
  Cosmos chain ID: genesis_29-2
  Blockchain utilitarian coin: L1
  Min. coin unit: el1
  1 L1 = 1 000 000 000 000 000 000 el1 	
  Initial supply: 21 000 000 L1
  genesis_29-2 at the time of upgrade circulation: ~29 000 000 L1
  Mint rate: < 20% annual
  Block target time: ~11s
  Binary name: genesisd
  genesis_29-1 start: Nov 30, 2021
  genesis_29-2 (evmos) start: Apr 16, 2022
  genesis_29-2 (cronos) start: Aug 26, 2023
  
EOF

moniker=""
minimum_combined_gb=150
repo_dir=$(cd "$(dirname "$0")" && pwd)
total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_swap_kb=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
total_combined_gb=$((($total_ram_kb + $total_swap_kb) / 1024 / 1024))
available_disk_gb=$(df -BG --output=avail / | awk 'NR==2 {print $1}' | tr -d 'G')
disk_headroom_gb=50

# Function to add a line to a file if it doesn't already exist (to prevent duplicates)
# Usage: add_line_to_file "line" file [use_sudo]
add_line_to_file() {
    local line="$1"
    local file="$2"
    local use_sudo="$3"

    if ! grep -qF "$line" "$file"; then
        if $use_sudo; then
            echo "$line" | sudo tee -a "$file" > /dev/null
        else
            echo "$line" >> "$file"
        fi

        echo "Line '$line' added to $file."
    else
        echo "Line '$line' already exists in $file."
    fi
}

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as the root user."
    exit 1
fi

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <command> [moniker]"
    echo "   <command> should be either 'upgrade' or 'init'"
    exit 1
fi

case "$1" in
    "upgrade")
        if [ "$#" -eq 1 ]; then
            moniker=$(grep "moniker" ~/.genesisd/config/config.toml | cut -d'=' -f2 | tr -d '[:space:]"')
            
            if [ -z "$moniker" ]; then
                echo "Error: No moniker found in the current configuration nor has one been provided as an argument."
                exit 1
            fi
            
            echo "Upgrade mode with moniker from previous configuration: $moniker"
        elif [ "$#" -eq 2 ]; then
            moniker="$2"
            echo "Upgrade mode with moniker: $moniker"
        else
            echo "Invalid number of arguments for 'upgrade' mode. Usage: $0 upgrade [moniker]"
            exit 1
        fi
        ;;
    "init")
        if [ "$#" -eq 2 ]; then
            moniker="$2"
            echo "Init mode with moniker: $moniker"
        else
            echo "Missing or invalid argument for 'init' mode. Usage: $0 init <moniker>"
            exit 1
        fi
        ;;
    *)
        echo "Invalid command: $1. Please use 'upgrade' or 'init'."
        exit 1
        ;;
esac

# ADD ADDITIONAL SWAP (IF NECESSARY)
if [ "$total_combined_gb" -lt "$minimum_combined_gb" ]; then
    # Calculate additional swap space needed in gigabytes
    additional_swap_gb=$((minimum_combined_gb - total_combined_gb + 1)) 

    if [ "$available_disk_gb" -lt "$((additional_swap_gb + disk_headroom_gb))" ]; then
        echo ""
        echo "Sorry, your node is too tiny in disk for genesisL1 :)."
        echo "Available disk space: ${available_disk_gb}GB."
        echo "Required disk space (bare minimum): $((additional_swap_gb + disk_headroom_gb))GB"
        exit 1
    fi

    echo "Adding ${additional_swap_gb}GB of swap space..."

    # Find a suitable name for the new swap file
    index=2
    new_swapfile="/genesisd_swapfile"
    while [ -e $new_swapfile ]; do
        new_swapfile="/genesisd_swapfile_$index"
        index=$((index + 1))
    done

    # Create new swap file
    fallocate -l ${additional_swap_gb}G $new_swapfile
    chmod 600 $new_swapfile
    mkswap $new_swapfile
    swapon $new_swapfile

    echo "Additional ${additional_swap_gb}GB of swap space added in $new_swapfile."

    # Add entry to /etc/fstab to make swapfile persistent
    add_line_to_file "$new_swapfile none swap sw 0 0" /etc/fstab true
else
    echo "No additional swap space needed."
fi

sleep 15s

# SYSTEM UPDATE, INSTALLATION OF THE FOLLOWING PACKAGES: jq git wget make gcc build-essential snapd wget ponysay, INSTALLATION OF GO 1.20 via snap

sudo apt-get update -y
sudo apt-get install jq git wget make gcc build-essential snapd wget -y
snap install go --channel=1.20/stable --classic
snap refresh go --channel=1.20/stable --classic

export PATH=$PATH:$(go env GOPATH)/bin
add_line_to_file 'export PATH=$PATH:$(go env GOPATH)/bin' ~/.bashrc false

# GLOBAL CHANGE OF OPEN FILE LIMITS
add_line_to_file "* - nofile 50000" /etc/security/limits.conf false
add_line_to_file "root - nofile 50000" /etc/security/limits.conf false
add_line_to_file "fs.file-max = 50000" /etc/sysctl.conf false
ulimit -n 50000

#PONYSAY 
snap install ponysay
ponysay "Installing genesisd from source code with updated genesis_29-2 mainnet!"
sleep 5s
ponysay "WARNING: cosmosvisor, evmosd processes will be killed and genesis, genesisd, evmos, evmosd system services will be stopped with this script on the next step. If you have other blockchains running, you might want to delete those parts of the script!"
sleep 20s

#STOPPING EVMOSD DAEMON AND COSMOVISOR IF IT WAS NOT STOPPED
pkill evmosd
pkill cosmovisor
service genesis stop
service genesisd stop
service evmos stop
service evmosd stop

# BACKUP genesis_29-2 (evmos version) .genesisd
cd
rsync -r --verbose --exclude 'data' ./.genesisd/ ./.genesisd_backup/

# DELETING OF .genesisd FOLDER (PREVIOUS INSTALLATIONS)
cd
rm -rf .genesisd

# BUILDING genesisd BINARIES
cd $repo_dir
go mod tidy
make install

# COPY .genesisd_backup FOLDER to .genesisd FOLDER, EXCLUDE data
cd
rsync -r --verbose --exclude 'data' ./.genesisd_backup/ ./.genesisd/

# SETTING UP THE NEW chain-id in CONFIG
genesisd config chain-id genesis_29-2

# INIT MODE WILL CREATE A NEW KEY
if [ "$1" = "init" ]; then
    genesisd config keyring-backend os

    ponysay "IN A FEW MOMENTS GET READY TO WRITE YOUR SECRET SEED PHRASE FOR YOUR NEW KEY NAMED *mygenesiskey*, YOU WILL HAVE 2 MINUTES FOR THIS!!!"
    sleep 20s
    genesisd keys add mygenesiskey --keyring-backend os --algo eth_secp256k1

    # Check if the exit status of the previous command is equal to zero (zero means it succeeded, anything else means it failed)
    if [ $? -eq 0 ]; then
      sleep 120s
    fi

    genesisd init $moniker --chain-id genesis_29-2 
fi

#IMPORTING GENESIS STATE
cd 
cd .genesisd/config
rm -r genesis.json
wget http://135.181.135.29/genesisd/genesis.json
cd

# RESET TO IMPORTED genesis.json
genesisd tendermint unsafe-reset-all

# CONFIG FILES
cd ~/.genesisd/config

# these default toml files already have genesis specific configurations set (i.e. timeout_commit 10s, min gas price 50gel etc.).
cp "$repo_dir/genesisd_config/default_app.toml" ./app.toml
cp "$repo_dir/genesisd_config/default_config.toml" ./config.toml

# set moniker
sed -i "s/moniker = \"\"/moniker = \"$moniker\"/" config.toml
echo "Moniker value set to: $moniker"

# SETTING genesisd AS A SYSTEMD SERVICE
sudo cp "$repo_dir/genesisd.service" /etc/systemd/system/genesisd.service
systemctl daemon-reload
systemctl enable genesisd
# echo "All set!" 
sleep 3s

# STARTING NODE
cat << "EOF"
     	    \\
             \\_
          .---(')
        o( )_-\_
       Node start                                                                                                                                                                                     
EOF
 
sleep 5s
systemctl start genesisd

# genesisd start
ponysay "genesisd node service started, you may try *journalctl -fu genesisd -ocat* or *service genesisd status* command to see it! Welcome to GenesisL1 blockchain!"
