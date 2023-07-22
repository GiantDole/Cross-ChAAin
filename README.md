# Cross-ChAAin
## A EthGlobal Paris 2023 Hackathon Project

TL;DR: 
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


### Our Work

#### Adjusted Trampoline
Trampoline only supported sending ether with a SCW. As we didn't have a front-end developer, this was the hardest to figure out. We had to extend it for our purposes:

- Customizing the Front-End: We redefined the user interface to cater to our specific use-case requirements. Namely, we allow the user to choose the source currency and destination chain.
- Integrating Custom Smart Contract Wallets: We extended the functionality to accommodate our own smart contract wallet and its functions.
- Developing Custom User Operations (userOps): Our front-end is building userOps dependent on the context.

#### Paymaster Logic
The paymaster logic is somewhat reinventing the wheel. There are services like Biconomy that allow you to pay for transaction fees with ERC20. However, they have modified mempools that, e.g., allow for approvals in the validation function. We wanted to play around and see if we could achieve 

- Payment Validation: Our logic ensures the paymaster receives its due compensation post-execution. We added checks to ensure the value of the token is adequate to meet transaction fees.
- Risk Management: An additional 2% of ERC20 is accrued to offset any potential risks.

#### Smart Contract Wallet 
Our custom smart contract wallet provides:

- ERC20 to ETH Swapping Capabilities: Users can seamlessly exchange their ERC20 tokens for ETH.
- L2 Deposit Functionality: It's streamlined for users wishing to deposit into L2.
#### Automation Scripts
For a smooth onboarding and setup we streamlined the initialization. We've developed scripts that facilitate the setup, paving the way for jurors to quickly achieve our recommended starting configuration.
### MVP Solution

### Features