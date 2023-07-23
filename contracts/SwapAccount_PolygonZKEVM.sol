// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '@account-abstraction/contracts/core/BaseAccount.sol';

import './interfaces/IAggregatorV3Interface.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IPolygonZKEVMBridge.sol';
import './PriceOracle.sol';

contract SwapAccount_PolygonZKEVM is
    PriceOracle,
    BaseAccount,
    UUPSUpgradeable,
    Initializable
{
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    address immutable POLYGONZKEVM_BRIDGE;
    address immutable WETH;
    //IAggregatorV3Interface immutable DATA_FEED;

    address public owner;

    IEntryPoint private immutable _entryPoint;

    event SwapAccountInitialized(
        IEntryPoint indexed entryPoint,
        address indexed owner
    );

    event Test(address owner);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(
        IEntryPoint anEntryPoint,
        address weth,
        address uniRouter,
        address polygonZKEVMBridge //address dataFeedAddress
    ) PriceOracle(uniRouter) {
        _entryPoint = anEntryPoint;
        POLYGONZKEVM_BRIDGE = polygonZKEVMBridge;
        WETH = weth;
        //DATA_FEED = IAggregatorV3Interface(dataFeedAddress);
        _disableInitializers();
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(
            msg.sender == owner || msg.sender == address(this),
            'only owner'
        );
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external {
        _requireFromEntryPointOrOwner();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(
        address[] calldata dest,
        bytes[] calldata func
    ) external {
        _requireFromEntryPointOrOwner();
        require(dest.length == func.length, 'wrong array lengths');
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of SimpleAccount must be deployed with the new EntryPoint address, then upgrading
     * the implementation by calling `upgradeTo()`
     */
    function initialize(address anOwner) public virtual initializer {
        _initialize(anOwner);
    }

    function _initialize(address anOwner) internal virtual {
        owner = anOwner;
        emit SwapAccountInitialized(_entryPoint, owner);
    }

    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner() internal view {
        require(
            msg.sender == address(entryPoint()) || msg.sender == owner,
            'account: not Owner or EntryPoint'
        );
    }

    /// implement template method of BaseAccount
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (owner != hash.recover(userOp.signature))
            return SIG_VALIDATION_FAILED;
        return 0;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) public onlyOwner {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override {
        (newImplementation);
        _onlyOwner();
    }

    /*function getRequiredTokAmountForGas_ChainlinkOracle(
        uint256 requiredETHForGas
    ) internal view returns (uint256) {
        (, int answer, , , ) = DATA_FEED.latestRoundData();
        return uint256(answer) * requiredETHForGas;
    }*/

    function swapTokensForExactETH(
        address paymaster,
        uint256 ethPaymentRequired,
        address tokenIn,
        uint256 amountInMax,
        uint256 amountOut
    ) external {
        //require(path.length >= 2, 'swapTokensForExactETH - invalid path');
        //address tokenIn = path[0];
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = WETH;

        //uint256 tokensRequired =
        _approvePaymaster(paymaster, ethPaymentRequired, tokenIn);

        /*if (
            IERC20(tokenIn).balanceOf(address(this)) <
            tokensRequired + amountInMax
        ) {
            amountInMax =
                IERC20(tokenIn).balanceOf(address(this)) -
                tokensRequired;
        }*/

        // Get uniswapV2 router
        IUniswapV2Router02 router = IUniswapV2Router02(UNISWAPV2_ROUTER);

        IERC20(tokenIn).safeApprove(UNISWAPV2_ROUTER, amountInMax);

        try
            router.swapTokensForExactETH(
                amountOut,
                amountInMax,
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            revert('swapTokensForExactETH');
        }
    }

    function swapTokensForExactTokens(
        address paymaster,
        uint256 ethPaymentRequired,
        address tokenA,
        uint256 amountInMax,
        address tokenB,
        uint256 amountOut
    ) external {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        //uint256 tokensAForGas =
        _approvePaymaster(paymaster, ethPaymentRequired, tokenA);

        /** 
        if (
            IERC20(tokenA).balanceOf(address(this)) <
            amountInMax + tokensAForGas
        ) {
            amountInMax =
                IERC20(tokenA).balanceOf(address(this)) -
                tokensAForGas;
        }*/

        // --- Perform the swap token A VS token B ---

        // Get uniswapV2 router
        IUniswapV2Router02 router = IUniswapV2Router02(UNISWAPV2_ROUTER);
        // Approve token
        IERC20(tokenA).approve(UNISWAPV2_ROUTER, amountInMax);
        try
            router.swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            revert('swapTokensForExactETH');
        }
    }

    /// @notice bridges the specified amount of tokens or ETH to PolygonZKEVM
    /// @param paymaster the paymaster that should be approved to transfer sufficient funds from this SCW
    /// @param destination the destination address on PolygonZKEVM that should receive the tokens/ETH
    /// @param amount the amount of tokens/ETH that should be transferred to PolygonZKEVM
    /// @param token the token address that should be depositted to PolygonZKEVM. If the address is 0x0, this will transfer ETH instead.
    function bridgeToL1(
        address paymaster,
        uint256 ethPaymentRequired,
        address token,
        uint256 amount,
        address destination
    ) external {
        uint256 ethAmount = 0;
        //uint256 tokensRequired =
        _approvePaymaster(paymaster, ethPaymentRequired, token);

        //if (IERC20(token).balanceOf(address(this)) < amount + tokensRequired) {
        //    amount = IERC20(token).balanceOf(address(this)) - tokensRequired;
        //}

        if (token != address(0x0)) {
            IERC20(token).safeApprove(POLYGONZKEVM_BRIDGE, amount);
        } else {
            ethAmount = amount; //this shouldn't be done atm
        }

        IPolygonZkEVMBridge(POLYGONZKEVM_BRIDGE).bridgeAsset{value: ethAmount}(
            0x0,
            destination,
            amount,
            token,
            true,
            ''
        );
    }

    /// @notice approves the paymaster for the required amount of specified ERC20 tokens
    /// @param paymaster the address of the paymaster to approve
    /// @param ethPaymentRequired the total cost of ETH for the entire transaction
    /// @param tokenIn the ERC20 token used for payment
    /// @return the amount of tokens required to be paid to the paymaster
    function _approvePaymaster(
        address paymaster,
        uint256 ethPaymentRequired,
        address tokenIn
    ) internal returns (uint256) {
        uint256 tokensRequired = getRequiredTokAmountForGas_UniswapOracle(
            tokenIn,
            WETH,
            ethPaymentRequired
        );

        IERC20(tokenIn).safeApprove(paymaster, tokensRequired);

        return tokensRequired;
        //return 0;
    }
}
