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

contract SwapAccount is
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

    function test(address test) external {
        emit Test(test);
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
        uint256 amountOut,
        uint256 amountInMax,
        address tokenIn
    ) external {
        //require(path.length >= 2, 'swapTokensForExactETH - invalid path');
        //address tokenIn = path[0];
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = WETH;

        uint256 tokensRequired = getRequiredTokAmountForGas_UniswapOracle(
            tokenIn,
            WETH,
            ethPaymentRequired
        );

        if (
            IERC20(tokenIn).balanceOf(address(this)) <
            tokensRequired + amountInMax
        ) {
            amountInMax =
                IERC20(tokenIn).balanceOf(address(this)) -
                tokensRequired;
        }

        IERC20(tokenIn).safeApprove(paymaster, tokensRequired);

        // Get uniswapV2 router
        IUniswapV2Router02 router = IUniswapV2Router02(UNISWAPV2_ROUTER);

        // if amount == type(uint256).max return balance of Proxy
        // amountInMax = IERC20(tokenIn).balanceOf(address(this));

        // Approve token
        //IERC20(tokenIn).safeApprove(UNISWAPV2_ROUTER, 0);

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

        IERC20(tokenIn).safeApprove(UNISWAPV2_ROUTER, tokensRequired);
    }

    function bridgeToPolygonZKEVM(
        address paymaster,
        uint256 ethPaymentRequired,
        address destination,
        uint256 amount,
        address token
    ) external {
        uint256 ethAmount = 0;

        if (token != address(0x0)) {
            IERC20(token).safeApprove(POLYGONZKEVM_BRIDGE, amount);
        } else {
            ethAmount = amount;
        }

        IPolygonZkEVMBridge(POLYGONZKEVM_BRIDGE).bridgeAsset{value: ethAmount}(
            0x1,
            destination,
            amount,
            token,
            true,
            bytes('0')
        );
    }
}
