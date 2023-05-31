# External Adapter for Domain Contract Binding

The external adapter takes two params domain name and address of the Dapp Registry contract. For every contract address listed in domain/contracts.json, it calls _dappRegistry.isMyContract(address)_. If and only if all addresses are valid, it will return true otherwise it will return false.

## Install Locally

Install dependencies:

```bash
yarn
```
### Run

```bash
yarn start
```

## Input Params

- `domain`: Domain Name
- `drcAddress`: Address of DRC contract

## Output

```json
{"jobRunID":0,"data":false,"result":false,"statusCode":200}
```

 ## Call the external adapter/API server
 
 
```bash
curl -X POST -H "content-type:application/json" "http://localhost:8080/" --data '{"id": 0, "data": {"domain" : "eth-to-weth.vercel.app", "drcAddress" : "0xdDbE8622d805bb9dc67EDD4Cb00fFc5af9119280"}}'
 ```
 
