// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import '@account-abstraction/contracts/core/BasePaymaster.sol';

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IUniswapV2Router02.sol';

/// @title Paymaster
///
/// @notice An ERC-4337 Paymaster contract which is able to sponsor gas fees for an ERC-20 swap
/// in exchange for some of the ERC20 tokens. This enables smart contract wallets to swap ERC-20s
/// without ever needing to posses native ETH.
///
/// @notice This includes support for cross-chain swaps onto Layer 2 chains such as Polygon zkEVM.
///

contract Paymaster is BasePaymaster {
    // Handle ERC20s which return false on failure
    using SafeERC20 for IERC20;

    // Events to be emitted
    event transferAmountCalculated(uint256 amount);
    event PaymasterValidationFailed(uint256 error);
    event ConfigUpdated(PaymasterConfig config);
    event UpdateCachedRate(uint256);
    event PostOpSecondTrySuccess();
    event PostOpRecoveryFailure();
    event PostOpRecoverySucces();

    /// @notice Only known Wallets may be used currently
    mapping(bytes32 => bool) public isAllowedByteCode;

    /// @notice Discriminators for the verified functions in the smart contract wallet
    mapping(uint32 => bool) public isAllowedDiscrim;

    // Configurable Paymaster-Wide Values
    struct PaymasterConfig {
        /// @notice Estimated gas cost for refunding tokens after the transaction is completed, such as 40000
        uint256 refundPostopCost;
        /// @notice Price Markup to make the Paymaster Profitable if desired
        uint32 priceMarkup;
        /// @notice Denominator, such as 1e6
        uint256 priceDenominator;
        /// @notice Address of the Uniswap Router used as a price oracle
        address UNISWAPV2_ROUTER;
        /// @notice ERC-20 with the same value as ETH, used to check prices with the oracle
        address wEthForOracle;
    }
    PaymasterConfig private paymasterConfig;

    // Structure of data passed between validate and postOp
    struct PaymasterContext {
        address gasCompToken;
        address sender;
        uint256 rate;
    }

    /// @dev Should consist of 4-byte discriminator followed by parameters of function
    struct SwapCallData {
        uint32 discrim;
        address paymaster;
        uint256 preGas;
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
    }

    /// @notice Cache rate of multiplication for each ERC-20 token address supported
    mapping(address => uint256) cachedRates;

    /// @notice Initializes the paymaster contract with the given parameters.
    /// @param _entryPoint The EntryPoint contract used in the Account Abstraction infrastructure.
    /// @param _owner The address that will be set as the owner of the contract.
    /// @param _config The initial configuration of the paymaster
    constructor(
        IEntryPoint _entryPoint,
        address _owner,
        PaymasterConfig memory _config
    ) BasePaymaster(_entryPoint) {
        transferOwnership(_owner);
        paymasterConfig = _config;
    }

    /// @notice Allows the contract owner to withdraw a specified amount of tokens from the contract.
    /// @param token The token to withdraw
    /// @param to The address to transfer the tokens to.
    /// @param amount The amount of tokens to transfer.
    function withdrawToken(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }

    /// @notice Updates the price markup and price update threshold configurations.
    /// @param _config The new configuration
    function updateConfig(PaymasterConfig calldata _config) external onlyOwner {
        paymasterConfig = _config;
        emit ConfigUpdated(_config);
    }

    /// @notice Updates the set of verified smart contract wallets
    /// @param _byteCodeHash The hash of the bytecode to allow or disallow
    /// @param _isAllowed `true` to allow this bytecode hash, `false`
    function updateAllowedByteCode(
        bytes32 _byteCodeHash,
        bool _isAllowed
    ) public onlyOwner {
        isAllowedByteCode[_byteCodeHash] = _isAllowed;
    }

    /// @notice Updates the set of permitted functions
    /// @param _discrim The descriminator of the function to allow or disallow
    /// @param _isAllowed `true` to allow this bytecode hash, `false`
    function updateAllowedDiscrim(
        uint32 _discrim,
        bool _isAllowed
    ) public onlyOwner {
        isAllowedDiscrim[_discrim] = _isAllowed;
    }

    /// @notice Updates the rate for the token
    function updateCachedRate(address token) public onlyOwner {
        cachedRates[token] = _priceOracle(token);
        emit UpdateCachedRate(cachedRates[token]);
    }

    /// @notice Returns x, such that nativeEthGas * x / 1e18 = tokensForGas
    /// @param token the token whose price to check
    ///
    function _priceOracle(address token) public returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = paymasterConfig.wEthForOracle;

        IUniswapV2Router02 router = IUniswapV2Router02(
            paymasterConfig.UNISWAPV2_ROUTER
        );

        uint256[] memory amounts = router.getAmountsOut(1e18, path);
        return amounts[1];
    }

    /// @notice Validates a paymaster user operation and calculates the required token amount for the transaction.
    /// @param userOp The user operation data.
    //  @param userOpHash hash of the user's request data.
    /// @param requiredPreFund The amount of tokens required for pre-funding.
    /// @return context_bytes The context containing the token amount and user sender address (if applicable).
    /// @return validationResult A uint256 value indicating the result of the validation (0 if successful).
    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 requiredPreFund
    )
        internal
        override
        returns (bytes memory context_bytes, uint256 validationResult)
    {
        (userOpHash);

        // 1) Verify smart contract wallet
        address extAddr = userOp.sender;
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(extAddr)
        }
        if (!isAllowedByteCode[codeHash]) {
            // Reject invalid wallet
            emit PaymasterValidationFailed(1);
            return ('', _packValidationData(true, 0, 0));
        }

        // 2) Verify function called in smart contract wallet
        SwapCallData memory data = abi.decode(userOp.callData, (SwapCallData));
        if (!isAllowedDiscrim[data.discrim]) {
            // Reject invalid function
            emit PaymasterValidationFailed(2);
            return ('', _packValidationData(true, 0, 0));
        }

        // 3) Verify paymaster will be sent ERC-20
        if (data.paymaster != address(this)) {
            // Reject invalid target address
            emit PaymasterValidationFailed(3);
            return ('', _packValidationData(true, 0, 0));
        }

        // 4) Verify gas prefund claim
        if (requiredPreFund != data.preGas) {
            // Reject invalid native gas estimate
            emit PaymasterValidationFailed(4);
            return ('', _packValidationData(true, 0, 0));
        }

        // 5) Verify input ERC-20 token
        if (cachedRates[data.tokenIn] == 0) {
            // Reject invalid ERC-20 token
            emit PaymasterValidationFailed(5);
            return ('', _packValidationData(true, 0, 0));
        }

        // 6) Verify sufficient volume
        uint256 tokensCoveringPrefund = requiredPreFund *
            cachedRates[data.tokenIn];
        if (data.amountIn <= tokensCoveringPrefund) {
            // Reject swap that is too small to cover gas
            emit PaymasterValidationFailed(6);
            return ('', _packValidationData(true, 0, 0));
        }

        // Pack context
        PaymasterContext memory context = PaymasterContext({
            gasCompToken: data.tokenIn,
            sender: userOp.sender,
            rate: cachedRates[data.tokenIn]
        });
        context_bytes = abi.encode(context);

        // Approve validation
        validationResult = _packValidationData(false, 0, 0);
        return (context_bytes, validationResult);
    }

    /// @notice Performs post-operation tasks, ensuring the paymaster is duly compensated.
    /// @dev This function is called after a user operation has been executed or reverted,
    ///      and for a second time if postOp reverted the first time.
    /// @param mode The post-operation mode (either successful, user reverted, or postOp reverted).
    /// @param context_bytes The context returned by validatePaymasterUserOp
    /// @param actualGasCost The actual gas cost used so far (before this postOp)
    function _postOp(
        PostOpMode mode,
        bytes calldata context_bytes,
        uint256 actualGasCost
    ) internal override {
        // Unpack Context
        PaymasterContext memory context = abi.decode(
            context_bytes,
            (PaymasterContext)
        );

        // Calculate a fair ERC-20 compensation for the paymaster
        uint256 transferAmount = ((actualGasCost +
            paymasterConfig.refundPostopCost *
            tx.gasprice) *
            context.rate *
            paymasterConfig.priceMarkup) /
            (1e18 * paymasterConfig.priceDenominator);
        emit transferAmountCalculated(transferAmount);

        // Handle 3 possible scenarios
        if (mode == PostOpMode.opSucceeded) {
            // User Operation Succeeded

            // Account Abstraction Wallet pays for operation with ERC-20
            IERC20(context.gasCompToken).safeTransferFrom(
                context.sender,
                address(this),
                transferAmount
            );

            // Compensation Successfully Acquired
            return;
        }
        if (mode == PostOpMode.opReverted) {
            // User Operation Reverted

            // First try to recover tokens
            (bool success, ) = address(context.gasCompToken).call(
                abi.encodePacked(
                    IERC20(context.gasCompToken).transferFrom.selector,
                    abi.encode(context.sender, address(this), transferAmount)
                )
            );
            if (success) {
                // Compensation Successfully Acquired
                emit PostOpRecoverySucces();
                return;
            } else {
                // Return to avoid disrepute
                emit PostOpRecoveryFailure();
                return;
            }
        }
        if (mode == PostOpMode.postOpReverted) {
            // First postOp call reverted

            // Recover tokens
            IERC20(context.gasCompToken).safeTransferFrom(
                context.sender,
                address(this),
                transferAmount
            );
            emit PostOpSecondTrySuccess();
            return;
        }
        /// @dev Unreachable, enum exhausted
    }
}
