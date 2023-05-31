# Domain Contract Binding

## Install Locally

Install dependencies:

```bash
npm install
```

ENV FILE


Add your private keys and RPC URL to .env file.

### Deploy contracts

```bash
npx hardhat deploy
```

### Setup Chainlink Node and external adapter

You can follow this [docs](https://docs.chain.link/chainlink-nodes/v1/running-a-chainlink-node) to setup node.

Run [external adpter](../External%20Adapter).

Add external adapter to your node.

### Run test

Add your domain name in the test script.


```bash
npx hardhat test --network sepolia --grep "Contract Address on /contracts.json are not valid"
npx hardhat test --network sepolia --grep "Contract Address on /contracts.json are valid"
```

Test cool-off functionality,

```bash
npx hardhat test --network sepolia --grep "CoolDown Period not over"
npx hardhat test --network sepolia --grep "CoolDown Period is over"
```


 
