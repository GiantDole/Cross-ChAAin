// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import '@openzeppelin/contracts/utils/Create2.sol';
import '@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol';

import './SwapAccount.sol';

/**
 * A factory contract for SwapAccount
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract SwapAccountFactory {
    SwapAccount public immutable accountImplementation;

    constructor(IEntryPoint _entryPoint, address dataFeedAddress) {
        accountImplementation = new SwapAccount(
            _entryPoint,
            address(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6), //WETH address
            address(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45), //UniswapV2
            address(0xF6BEEeBB578e214CA9E23B0e9683454Ff88Ed2A7), //PolygonZKEVM
            dataFeedAddress
        );
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(
        address owner,
        uint256 salt
    ) public returns (SwapAccount ret) {
        address addr = getAddress(owner, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return SwapAccount(payable(addr));
        }
        ret = SwapAccount(
            payable(
                new ERC1967Proxy{salt: bytes32(salt)}(
                    address(accountImplementation),
                    abi.encodeCall(SwapAccount.initialize, (owner))
                )
            )
        );
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        return
            Create2.computeAddress(
                bytes32(salt),
                keccak256(
                    abi.encodePacked(
                        type(ERC1967Proxy).creationCode,
                        abi.encode(
                            address(accountImplementation),
                            abi.encodeCall(SwapAccount.initialize, (owner))
                        )
                    )
                )
            );
    }
}
