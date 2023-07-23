pragma solidity ^0.8.12;

import './interfaces/IUniswapV2Router02.sol';

contract PriceOracle {
    address immutable UNISWAPV2_ROUTER;

    constructor(address uniswap_router) {
        UNISWAPV2_ROUTER = uniswap_router;
    }

    function getRequiredTokAmountForGas_UniswapOracle(
        address tokenA,
        address tokenB,
        uint256 requiredETHForGas
    ) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        IUniswapV2Router02 router = IUniswapV2Router02(UNISWAPV2_ROUTER);

        uint256[] memory amounts = router.getAmountsOut(
            requiredETHForGas,
            path
        );
        return amounts[1];
    }
}
