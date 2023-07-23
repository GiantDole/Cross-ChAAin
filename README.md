# Cross-ChAAin
## A EthGlobal Paris 2023 Hackathon Project

Links:
- Successful gasless deposit to L2: https://www.jiffyscan.xyz/bundle/0xac98340b90471fad381a1ac4b524eadb69eb2d698f77e2ff7ca394d18f11474b?network=goerli&pageNo=0&pageSize=10
- Paymaster: 
  - Contract https://github.com/GiantDole/Cross-ChAAin/blob/main/contracts/Paymaster.sol
  - Deployed: https://www.jiffyscan.xyz/paymaster/0xad1437518fe6b2373db7256ac0f3d2dac7d9508f?network=goerli
- Smart Contract Wallet (Goerli):
  - Contract: https://github.com/GiantDole/Cross-ChAAin/blob/main/contracts/SwapAccount.sol
  - Deployed: https://goerli.etherscan.io/address/0xe38918628500106ae7eebced3a29a1e926eb5cf3#internaltx
- Smart Contract Wallet (PolygonZKEVM Testnet):
  - Contract: https://github.com/GiantDole/Cross-ChAAin/blob/main/contracts/SwapAccount_PolygonZKEVM.sol
  - Deployed: https://testnet-zkevm.polygonscan.com/address/0xe0b30aee4580b410fa05c7d5303f45d48236abdd#tokentxns
### Motivation
In the dynamic world of cryptocurrencies, it's a common frustration: holding an ERC20 token but lacking the ETH to fund transactions. Whether it's the limitation of smart contract wallets or the cumbersome need to fund with ETH just to make a simple swap, these roadblocks can deter even the most seasoned crypto enthusiast. Imagine wanting to deposit your ERC20s into Layer 2 for cost-effective operations, only to be sidetracked by the need to first fund your wallet with ETH.

Cross-ChAAin is our game-changing solution. With it, users can seamlessly swap ERC20 for ETH, directly exchange one ERC20 for another, or deposit ERC20 tokens into L2 without any ETH middleman steps. And with our innovative account abstraction contract on L2, you can deposit straight into L2 and then swap for its native currency. This is more than just convenience; it's a significant gas-saving move, ideal for those looking to operate within L2. 
### Vision
In the evolving landscape of blockchain technology, we foresee a world where Externally Owned Accounts (EOAs) harness the same capabilities as smart contract wallets. Imagine holding an ERC20 token in your EOA, performing intricate operations, all underpinned by a simple signature – that's the world Cross-ChAAin is forging towards.

We recognize that intricate swap operations can be costly on Layer 1 (L1). Yet, with the rapid advancements of Layer 2 technologies, it might often be more economical to route these swaps through L2. Our vision doesn't stop at providing an efficient route; it's about complete fluidity. With Cross-ChAAin's features, the journey from an L1 smart contract wallet depositing into L2, executing swaps, carrying out operations, and then withdrawing back to L1, becomes streamlined. And the most transformative part? All these actions can transpire without the presence of any ETH and necessitate just a single user interaction.

Cross-ChAAin is not just a tool – it's a vision of the future where blockchain operations are seamless, cost-effective, and elegantly simple.

### Current Limitations
Cross-ChAAin is pushing the boundaries of blockchain operations, but our current version has certain constraints:

1. EOA Approvals: Currently, EOAs can't authorize their tokens without ETH. While "ERC-2612: Permit Extension for EIP-20 Signed Approvals" offers a potential solution, our MVP focuses on SCWs holding ERC-20 tokens without any ETH.
1. Paymaster Validation: The paymaster can't ensure SCWs leave enough approved funds. Because of ETH requirements for prior approvals, our workaround employs a fixed SCW. The paymaster then checks the SCW's bytecode against predefined SCWs, ensuring enough ERC-20 funds for gas compensation. Dror Tirosh has highlighted that while it's challenging now, future infrastructure might simplify ERC-20 approvals during validation.

Our acknowledgment of these limitations charts our path forward.

### Existing Solutions

There are two types of solutions we have identified that currently exist to achieve something similar. However, they are limited as described in the following:
1. Private mempools: These are run by services such as Biconomy. However, they perform operations in the validate function of the paymaster that are not allowed within the standard ERC4337. This leads to limited participation and centralization of the bundler network operating on that private mempool. We wanted to implement an own solution that allows any bundler to process our userOps by adhering to the ERC4337 standard.
2. [Tokenpaymaster](https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/samples/TokenPaymaster.sol): While these contracts build the foundation of our solution, they are still griefable. There is no way to ensure in the validate function of the paymaster that there will be sufficient approved tokens by the end of executing the SCW function. While there is no way to implement a better generic paymaster, we have found a way to implement a application-specifc (Proof of Concept) paymaster that is not griefable. The paymaster is non-griefable because it verifies the bytecode of the SCW, ensuring that the execution will lead to sufficient approved tokens for the paymaster. Furthermore, it verifies the calldata and uses a cache to ensure that the tokens value is sufficient to cover the cost. The SCW then validates that the balance is high enough to cover the execution.

### Our Work

#### Adjusted Trampoline
We have extended Trampoline for our own purposes as follows:

- Customizing the Front-End: We redefined the user interface to cater to our specific use-case requirements. Namely, we allow the user to choose the source currency and destination chain.
- Integrating Custom Smart Contract Wallets: We extended the functionality to accommodate our own smart contract wallet and its functions.
- Contextual Custom User Operations (userOps): Our front-end is building userOps dependent on the context.

#### Paymaster Logic
Our paymaster logic is a novel approach to receive ERC20 tokens as payment. While we cache the ERC20 price to being able to calculate the required amount of tokens in the validate function, we also validate that the SCW is our implementation. This ensures that at the end of execution, there will be sufficient approved funds in the SCW to transfer to the paymaster:

- Payment Validation: Our logic ensures the paymaster receives its due compensation post-execution. We added checks to ensure the value of the token is adequate to meet transaction fees. Particularly, we verify the following things:
  1. The SCW's bytecode hash equals one of the whitelisted SCW's
  2. The function called in the SCW is a whitelisted function
  3. The paymaster address in the calldata is correct
  4. The gas specified in the calldata is correct
  5. Gas x cached price for the specified token (meaning its required amount) is smaller than the amount used (together with the validation in the SCW, this ensures that the execution will never revert)
- Risk Management: An additional 2% of ERC20 is accrued to offset any potential risks.

#### Smart Contract Wallet 
Our custom smart contract wallet provides:

- ERC20 to ETH Swapping Capabilities: Users can seamlessly exchange their ERC20 tokens for ETH.
- L2 Deposit Functionality: It's streamlined for users wishing to deposit into L2.
#### Scripts and Tests
For a smooth onboarding and setup we streamlined the initialization. We've developed scripts that facilitate the setup, paving the way for jurors to quickly achieve our recommended starting configuration.  
Furthermore, we have written Foundry tests to test edge-cases of our implementation. It should be noted that this is not exhaustive. 
### MVP Solution

We deployed our own paymaster and smart contract wallet on Ethereum. Additionally, we deployed a smart contract wallet on PolygonZKEVM. We could successfully bridge ERC-20 assets without gas in the smart contract wallet to PolygonZKEVM. 
While we've implemented other features such as swapping ERC-20 to ETH and ERC-20 to ERC-20, we weren't able to run those functions. However, most of our efforts in this project are a proof of concept and at least 70% of the time were spent understanding Account Abstraction and ideating the solution to existing problems.