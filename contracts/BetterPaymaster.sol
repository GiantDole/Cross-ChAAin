// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@account-abstraction/contracts/core/BasePaymaster.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Paymaster
/// @notice An ERC-4337 Paymaster contract which is able to sponsor gas fees for an ERC-20 swap
/// in exchange for some of the ERC20 tokens. This enables smart contract wallets to swap ERC-20s
/// without ever needing to posses native ETH.
/// TODO This includes cross-chain swaps onto Layer 2 chains such as Polygon zkEVM
/// The contract refunds excess tokens if the actual gas cost is lower than the provided amount.
/// It also allows updating configuration and withdrawing tokens by the contract owner.
/// The contract uses an Oracle (TODO ChainLink) to fetch the latest token prices.
/// @dev Inherits from BasePaymaster.

contract MyPaymaster is BasePaymaster {

    // Handle ERC20s which return false on failure
    using SafeERC20 for IERC20;
    
    /// @notice Only known Wallets may be used currently
    mapping (bytes32=>bool) public isAllowedByteCode;

    struct PaymasterConfig {
        /// @notice Estimated gas cost for refunding tokens after the transaction is completed, such as 40000
        uint256 refundPostopCost;
    }
    PaymasterConfig private paymasterConfig;
    event ConfigUpdated(PaymasterConfig config);


    /// @notice Initializes the paymaster contract with the given parameters.
    /// @param _entryPoint The EntryPoint contract used in the Account Abstraction infrastructure.
    /// @param _owner The address that will be set as the owner of the contract.
    /// @param _config The initial configuration of the paymaster
    constructor(IEntryPoint _entryPoint, address _owner, PaymasterConfig memory _config) BasePaymaster(_entryPoint) {
        transferOwnership(_owner);
        paymasterConfig = _config;
    }

    /// @notice Allows the contract owner to withdraw a specified amount of tokens from the contract.
    /// @param token The token to withdraw
    /// @param to The address to transfer the tokens to.
    /// @param amount The amount of tokens to transfer.
    function withdrawToken(ERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    /// @notice Updates the price markup and price update threshold configurations.
    /// @param _config The new configuration
    function updateConfig(PaymasterConfig _config) external onlyOwner {
        paymasterConfig = _config;
        emit ConfigUpdated(_config);
    }

    /// @notice Updates the set of verified smart contract wallets
    /// @param _config The new configuration
    /// @param _isAll
    function updateAllowedByteCode(bytes32 _byteCodeHash, bool _isAllowed) public onlyOwner {
        isAllowedByteCode[_byteCodeHash] = _isAllowed;
    }

    /// @notice Validates a paymaster user operation and calculates the required token amount for the transaction.
    /// @param userOp The user operation data.
    /// @param userOpHash hash of the user's request data.
    /// @param requiredPreFund The amount of tokens required for pre-funding.
    /// @return context The context containing the token amount and user sender address (if applicable).
    /// @return validationResult A uint256 value indicating the result of the validation (0 if successful).
    function _validatePaymasterUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 requiredPreFund)
    internal override returns (bytes memory context, uint256 validationResult) {

        // Verify smart contract wallet
        address extAddr = userOp.sender;
        bytes32 codeHash;
        assembly { codeHash := extcodehash(extAddr) }
        return ("", isAllowedByteCode[codeHash] ? 0 : 1);

        // TODO validate prefund is accurate
        // We know that the wallet does token.approve(paymaster, <calldata.prefund> * rate )
        // and require(token.balanceof(address(this)) > <calldata.prefund> * rate )
        // during validate and during execution
        // (except, it can't do that during validation probably due to restrictions)

        // Do not try safeTransferFrom() here since approval does not occur until execution.
        //context = abi.encodePacked(gasCompToken, );


    }

    /// @notice Performs post-operation tasks, ensuring the paymaster is duly compensated.
    /// @dev This function is called after a user operation has been executed or reverted,
    ///      and for a second time if postOp reverted the first time.
    /// @param mode The post-operation mode (either successful, user reverted, or postOp reverted).
    /// @param context The context returned by validatePaymasterUserOp or returned by first postOp call.
    /// @param actualGasCost The actual gas cost used so far (before this postOp)
    function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal override {
        if(mode == PostOpMode.opSucceeded) {
            // User op succeeded
            try /*TODO*/ {

            }
            catch {

            }
        }
        if (mode == PostOpMode.opReverted) {
            // User op reverted

            uint256 tokens_wanted; //TODO calculate

            // First try to recover tokens
            try  {
                //after try
            }
            catch {
                // bite the bullet
                return
            }
        }
        if (mode == PostOpMode.postOpReverted) {
            // First postOp call reverted
            
            // TODO transfer tokens again
            return
        }
        /// @dev unreachable, enum exhausted
    }
}