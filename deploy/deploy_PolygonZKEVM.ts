import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';
import config from '../src/exconfig';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, ethers } = hre;
    const accounts = await hre.getUnnamedAccounts();

    const deployment = await deployments.deploy('SwapAccount_PolygonZKEVM', {
        from: accounts[0],
        deterministicDeployment: true,
        args: [config.network.entryPointAddress, 0x3ce1bab7b7bAE26775F81Ee3576a99f0EAd5B33C, 0x0, 0xf6beeebb578e214ca9e23b0e9683454ff88ed2a7],
        log: true,
    });

    // ERC20 interface
    /*const ERC20 = await ethers.getContractFactory("ERC20");
    const tokenAddress = '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984';
    const token = ERC20.attach(tokenAddress);
  
    // Check balance of the deploying account
    const balance = await token.balanceOf(accounts[0]);
    const amountToTransfer = ethers.utils.parseUnits("3", 18);
  
    if (balance.lt(amountToTransfer)) {
      console.log(`Account ${accounts[0]} doesn't have enough tokens.`);
      return;
    }
  
    // Transfer tokens to deployed contract
    await token.connect(ethers.provider.getSigner(accounts[0])).transfer(deployment.address, amountToTransfer);
    console.log(`Transferred ${ethers.utils.formatUnits(amountToTransfer, 18)} tokens to ${deployment.address}`);*/
};

export default func;
