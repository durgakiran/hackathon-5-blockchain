# !/bin/sh

ROOTDIR=$(cd "$(dirname "$0")" && pwd)
echo $ROOTDIR
export PATH=${ROOTDIR}/../../bin:${PWD}/../../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../config
export VERBOSE=false

# import utils functions
. ./utils.sh

function generateGenisisBlockForOrderer() {
    which configtxgen
    if [ "$?" -ne 0 ]; then
        fatalln "configtxgen tool not found. exiting"
    fi
    infoln "Generating genesis block for orderer"

    mkdir -p ../output/ ../output/channel-artifacts

    configtxgen -profile SixOrgOrdererGenesis -channelID $CHANNEL_NAME -outputBlock ../output/channel-artifacts/genesis.block
    if [ "$?" -ne 0 ]; then
        echo "Failed to generate channel genesis block"
    fi
}

function createChannel() {
    which configtxgen
    if [ "$?" -ne 0 ]; then
        fatalln "configtxgen tool not found. exiting"
    fi
    infoln "Generating genesis block for orderer"

}

function createOrgs() {
    # remove existing organizations if already present
    if [ -d "organizations/peerOrganizations" ]; then
        rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
    fi

    # generate crypto material for organizations
    # here we are using cryptogen only
    if [ "$CRYPTO" == "cryptogen" ]; then
        which cryptogen
        if [ "$?" -ne 0 ]; then
            fatalln "cryptogen tool not found. exiting"
        fi
        infoln "Generating certificates using cryptogen tool"

        infoln "Creating BankOrg peer Identities"
        set -x
        cryptogen generate --config=../config/crypto-config-bank.yaml --output="../organizations"
        res=$?
        { set +x; } 2>/dev/null
        if [ $res -ne 0 ]; then
            fatalln "Failed to generate certificates..."
        fi

        infoln "Creating Collateral peer Identities"
        set -x
        cryptogen generate --config=../config/crypto-config-collateral.yaml --output="../organizations"
        res=$?
        { set +x; } 2>/dev/null
        if [ $res -ne 0 ]; then
            fatalln "Failed to generate certificates..."
        fi

        infoln "Creating insurance peer Identities"
        set -x
        cryptogen generate --config=../config/crypto-config-insurance.yaml --output="../organizations"
        res=$?
        { set +x; } 2>/dev/null
        if [ $res -ne 0 ]; then
            fatalln "Failed to generate certificates..."
        fi

        infoln "Creating transport peer Identities"
        set -x
        cryptogen generate --config=../config/crypto-config-transport.yaml --output="../organizations"
        res=$?
        { set +x; } 2>/dev/null
        if [ $res -ne 0 ]; then
            fatalln "Failed to generate certificates..."
        fi

        infoln "Creating warehouse peer Identities"
        set -x
        cryptogen generate --config=../config/crypto-config-warehouse.yaml --output="../organizations"
        res=$?
        { set +x; } 2>/dev/null
        if [ $res -ne 0 ]; then
            fatalln "Failed to generate certificates..."
        fi

        infoln "Creating Orderer Org Identities"

        set -x
        cryptogen generate --config=../config/crypto-config.yaml --output="../organizations"
        res=$?
        if [ $res -ne 0 ]; then
            fatalln "Failed to generate certificates..."
        fi
    fi

}

function networkUp() {
    createOrgs
    generateGenisisBlockForOrderer
}

# Using crpto vs CA. default is cryptogen
CRYPTO="cryptogen"
# Default channel that get's created and all organizations would be part of this
CHANNEL_NAME="mainChannel"

# Parse commandline args

## Parse mode
if [[ $# -lt 1 ]]; then
    printHelp
    exit 0
else
    MODE=$1
    shift
fi

# Are we generating crypto material with this command?
if [ ! -d "organizations/peerOrganizations" ]; then
    CRYPTO_MODE="with crypto from '${CRYPTO}'"
else
    CRYPTO_MODE=""
fi

# Determine mode of operation and printing out what we asked for
if [ "$MODE" == "up" ]; then
    infoln "Starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE}' ${CRYPTO_MODE}"
    networkUp
fi
