# !/bin/sh

ROOTDIR=$(cd "$(dirname "$0")" && pwd)
echo $ROOTDIR
export PATH=${ROOTDIR}/../../bin:${PWD}/../../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/config
export VERBOSE=false

# import utils functions
. ./utils.sh

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
}

# Using crpto vs CA. default is cryptogen
CRYPTO="cryptogen"


# Parse commandline args

## Parse mode
if [[ $# -lt 1 ]] ; then
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