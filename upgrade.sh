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


	 /$$   /$$ /$$$$$$$$  /$$$$$$  /$$       /$$$$$$ /$$$$$$$$ /$$   /$$ /$$$$$$  /$$$$$$ 
	| $$$ | $$| $$_____/ /$$__  $$| $$      |_  $$_/|__  $$__/| $$  | $$|_  $$_/ /$$__  $$
	| $$$$| $$| $$      | $$  \ $$| $$        | $$     | $$   | $$  | $$  | $$  | $$  \__/
	| $$ $$ $$| $$$$$   | $$  | $$| $$        | $$     | $$   | $$$$$$$$  | $$  | $$      
	| $$  $$$$| $$__/   | $$  | $$| $$        | $$     | $$   | $$__  $$  | $$  | $$      
	| $$\  $$$| $$      | $$  | $$| $$        | $$     | $$   | $$  | $$  | $$  | $$    $$
	| $$ \  $$| $$$$$$$$|  $$$$$$/| $$$$$$$$ /$$$$$$   | $$   | $$  | $$ /$$$$$$|  $$$$$$/
	|__/  \__/|________/ \______/ |________/|______/   |__/   |__/  |__/|______/ \______/ 
                                                                                                                                                                       
                                                                                      	 
	 /$$   /$$  /$$$$$$   /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$  /$$$$$$$$ /$$$$$$$$
	| $$$ | $$ /$$__  $$ /$$__  $$| $$__  $$| $$__  $$ /$$__  $$|__  $$__/| $$_____/	
	| $$$$| $$| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$   | $$   | $$      
	| $$ $$ $$| $$  | $$| $$  | $$| $$$$$$$ | $$  | $$| $$$$$$$$   | $$   | $$$$$   
	| $$  $$$$| $$  | $$| $$  | $$| $$__  $$| $$  | $$| $$__  $$   | $$   | $$__/   
	| $$\  $$$| $$  | $$| $$  | $$| $$  \ $$| $$  | $$| $$  | $$   | $$   | $$      
	| $$ \  $$|  $$$$$$/|  $$$$$$/| $$$$$$$/| $$$$$$$/| $$  | $$   | $$   | $$$$$$$$
	|__/  \__/ \______/  \______/ |_______/ |_______/ |__/  |__/   |__/   |________/
                                                                                                                                                            
                                                                                                                                                                                                                             	 
	Welcome to the decentralized blockchain Renaissance, above money & beyond cryptocurrency!
	This script should update genesis_29-2 (evmos version) to genesis_29-2 (cronos version) while running under root user.
	GENESIS L1 is a highly experimental decentralized project, provided AS IS, with NO WARRANTY.
	GENESIS L1 IS A NON COMMERCIAL OPEN DECENRALIZED BLOCKCHAIN PROJECT RELATED TO SCIENCE AND ART
          
  Mainnet EVM chain ID: 29
  Cosmos chain ID: genesis_29-2
  Blockchain utilitarian coin: L1
  Min. coin unit: el1
  1 L1 = 1 000 000 000 000 000 000 el1 	
  Initial supply: 21 000 000 L1
  genesis_29-2 circulation: ~29 000 000 L1
  Mint rate: < 20% annual
  Block target time: ~11s
  Binary name: genesisd
  genesis_29-1 start: Nov 30, 2021
  genesis_29-2 (evmos) start: Apr 16, 2022
  genesis_29-2 (cronos) start: Aug 26, 2023
EOF
sleep 15s


# SYSTEM UPDATE, INSTALLATION OF THE FOLLOWING PACKAGES: jq git wget make gcc build-essential snapd wget ponysay, INSTALLATION OF GO 1.20 via snap

sudo apt-get update -y
sudo apt-get install jq git wget make gcc build-essential snapd wget -y
snap install go --channel=1.20/stable --classic
snap refresh go --channel=1.20/stable --classic

export PATH=$PATH:$(go env GOPATH)/bin
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc

# GLOBAL CHANGE OF OPEN FILE LIMITS
echo "* - nofile 50000" >> /etc/security/limits.conf
echo "root - nofile 50000" >> /etc/security/limits.conf
echo "fs.file-max = 50000" >> /etc/sysctl.conf 
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
cd genesisL1
go mod tidy
make install

# COPY .genesisd_backup FOLDER to .genesisd FOLDER, EXCLUDE data
cd
rsync -r --verbose --exclude 'data' ./.genesisd_backup/ ./.genesisd/

# SETTING UP THE NEW chain-id in CONFIG
genesisd config chain-id genesis_29-2

#IMPORTING GENESIS STATE
cd
wget http://135.181.135.29/genesis.json_L1_v46 -O ./.genesisd/config/genesis.json

# RESET TO IMPORTED genesis.json
genesisd tendermint unsafe-reset-all

# ADD PEERS
cd ~/.genesisd/config
# sed -i 's/seeds = ""/seeds = "36111b4156ace8f1cfa5584c3ccf479de4d94936@65.21.34.226:26656"/' config.toml
# sed -i 's/rpc_servers = ""/rpc_servers = "http:\/\/154.12.229.22:26657,http:\/\/154.12.229.22:26657"/' config.toml
# sed -i 's/persistent_peers = ""/persistent_peers = "551cb3d41d457f830d75c7a5b8d1e00e6e5cbb91@135.181.97.75:26656,5082248889f93095a2fd4edd00f56df1074547ba@146.59.81.204:26651,36111b4156ace8f1cfa5584c3ccf479de4d94936@65.21.34.226:26656,c23b3d58ccae0cf34fc12075c933659ff8cca200@95.217.207.154:26656,37d8aa8a31d66d663586ba7b803afd68c01126c4@65.21.134.70:26656,d7d4ea7a661c40305cab84ac227cdb3814df4e43@139.162.195.228:26656,be81a20b7134552e270774ec861c4998fabc2969@genesisl1.3ventures.io:26656"/' config.toml
# sed -i 's/minimum-gas-prices = "0aphoton"/minimum-gas-prices = "0el1"/g' app.toml
# sed -i 's/timeout_commit = "5s"/timeout_commit = "10s"/' config.toml
# sed -i '212s/.*/enable = false/' app.toml

# ADDITIONAL SWAP (IF NECESSARY)
total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_swap_kb=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
total_combined_gb=$((($total_ram_kb + $total_swap_kb) / 1024 / 1024))
minimum_combined_gb=150

if ((total_combined_gb < minimum_combined_gb)); then
    # Calculate additional swap space needed in gigabytes
    additional_swap_gb=$((minimum_combined_gb - total_combined_gb + 1)) 

    echo "Adding ${additional_swap_gb}GB of swap space..."

    # Find a suitable name for the new swap file
    index=2
    new_swapfile="/swapfile"
    while [ -e $new_swapfile ]; do
        new_swapfile="/swapfile_$index"
        index=$((index + 1))
    done

    # Create new swap file
    fallocate -l ${additional_swap_gb}G $new_swapfile

    # Set permissions on the swap file
    chmod 600 $new_swapfile

    # Make the swap space
    mkswap $new_swapfile

    # Activate the new swap space
    swapon $new_swapfile

    echo "Additional ${additional_swap_gb}GB of swap space added in $new_swapfile."
else
    echo "No additional swap space needed."
fi

# SETTING genesisd AS A SYSTEMD SERVICE
wget https://raw.githubusercontent.com/alpha-omega-labs/genesisd/noobdate/genesisd.service -O /etc/systemd/system/genesisd.service
systemctl daemon-reload
systemctl enable genesisd
echo "All set!" 
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
