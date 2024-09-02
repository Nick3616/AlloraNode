#!/bin/bash

BOLD="\033[1m"
UNDERLINE="\033[4m"
DARK_YELLOW="\033[0;33m"
CYAN="\033[0;36m"
GREEN="\033[0;32m"
RESET="\033[0m"

execute_with_prompt() {
    echo -e "${BOLD}Executing: $1${RESET}"
    if eval "$1"; then
        echo "Command executed successfully."
    else
        echo -e "${BOLD}${DARK_YELLOW}Error executing command: $1${RESET}"
        exit 1
    fi
}

echo -e "${BOLD}${DARK_YELLOW}Updating system dependencies...${RESET}"
execute_with_prompt "sudo apt update -y && sudo apt upgrade -y"
echo

echo -e "${BOLD}${DARK_YELLOW}Installing required packages...${RESET}"
execute_with_prompt "sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4"
echo

echo -e "${BOLD}${DARK_YELLOW}Installing Docker...${RESET}"
execute_with_prompt 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg'
echo
execute_with_prompt 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
echo
execute_with_prompt 'sudo apt-get update'
echo
execute_with_prompt 'sudo apt-get install docker-ce docker-ce-cli containerd.io -y'
echo
sleep 2
echo -e "${BOLD}${DARK_YELLOW}Checking docker version...${RESET}"
execute_with_prompt 'docker version'
echo

echo -e "${BOLD}${DARK_YELLOW}Installing Docker Compose...${RESET}"
VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
echo
execute_with_prompt 'sudo curl -L "https://github.com/docker/compose/releases/download/'"$VER"'/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose'
echo
execute_with_prompt 'sudo chmod +x /usr/local/bin/docker-compose'
echo

echo -e "${BOLD}${DARK_YELLOW}Checking docker-compose version...${RESET}"
execute_with_prompt 'docker-compose --version'
echo

if ! grep -q '^docker:' /etc/group; then
    execute_with_prompt 'sudo groupadd docker'
    echo
fi

execute_with_prompt 'sudo usermod -aG docker $USER'
echo

echo -e "${BOLD}${UNDERLINE}${DARK_YELLOW}Cloning AlloraAiHuggingModel repository...${RESET}"
git clone https://github.com/HarbhagwanDhaliwal/AlloraAiHuggingModel.git
cd AlloraAiHuggingModel
echo

echo -e "${BOLD}${UNDERLINE}${DARK_YELLOW}Creating worker data directory...${RESET}"
mkdir -p worker-data
chmod -R 777 worker-data
echo

read -p "Enter WALLET_SEED_PHRASE: " WALLET_SEED_PHRASE
echo

echo -e "${BOLD}${UNDERLINE}${DARK_YELLOW}Generating config.json file...${RESET}"
cat <<EOF > config.json
{
   "wallet": {
       "addressKeyName": "Wallet Name",
       "addressRestoreMnemonic": "$WALLET_SEED_PHRASE",
       "alloraHomeDir": "/root/.allorad",
       "gas": "1000000",
       "gasAdjustment": 1.0,
       "nodeRpc": "https://allora-testnet-rpc.itrocket.net/",
       "maxRetries": 1,
       "delay": 1,
       "submitTx": false
   },
   "worker": [
       {
           "topicId": 2,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 3,
           "parameters": {
               "InferenceEndpoint": "http://inference:8000/inference/{Token}",
               "Token": "ETH"
           }
       },
       {
           "topicId": 4,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 2,
           "parameters": {
               "InferenceEndpoint": "http://inference:8000/inference/{Token}",
               "Token": "BTC"
           }
       },
       {
           "topicId": 6,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 5,
           "parameters": {
               "InferenceEndpoint": "http://inference:8000/inference/{Token}",
               "Token": "SOL"
           }
       }
   ]
}
EOF
echo -e "${BOLD}${DARK_YELLOW}config.json file generated successfully!${RESET}"
echo

echo -e "${BOLD}${UNDERLINE}${DARK_YELLOW}Initializing worker...${RESET}"
chmod +x init.config
./init.config
echo

echo -e "${BOLD}${UNDERLINE}${DARK_YELLOW}Building and starting Docker containers...${RESET}"
docker compose up --build -d
echo

echo -e "${BOLD}${DARK_YELLOW}Checking running Docker containers...${RESET}"
docker ps
echo
execute_with_prompt 'docker logs -f worker'
echo
