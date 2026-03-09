# simple env for my Bitcoin Core regtest work
export W="alexa_wallet"
export ADDR=$(bitcoin-cli -regtest -rpcwallet="$W" getnewaddress "" bech32)
echo "→ Wallet  : $W"
echo "→ Mine to : $ADDR"
