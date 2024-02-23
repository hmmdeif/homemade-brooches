# Deif's Homemade Brooches Contracts

![Main](https://github.com/hmmdeif/homemade-brooches/actions/workflows/test.yml/badge.svg)

## Build

`forge build`

## Test

`forge test`

## Deploy

Uses env vars from a file `.env`. Copy and rename `.env.sample` and fill in the required variables.

```
# To load the variables in the .env file
source .env

# To deploy and verify our contract
forge script script/HomemadeBroochNFT.s.sol:DeployBrooches --rpc-url $RPC_URL --broadcast -vvvv --slow

# To verify
forge script script/HomemadeBroochNFT.s.sol:DeployBrooches --rpc-url $RPC_URL --verify -vvvv --resume
```

## Troubleshooting

#### Test contracts are too large

You need to update foundry to a later build. This error is suppressed in later versions for test contracts.

#### Deploy script transaction failures

`--slow` is necessary to stop all tx being sent and being mined out of order.