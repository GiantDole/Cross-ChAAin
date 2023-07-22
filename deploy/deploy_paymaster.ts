import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import config from '../src/exconfig';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, ethers } = hre;
  const accounts = await hre.getUnnamedAccounts();

  const deployment = await deployments.deploy('TestPaymasterAcceptAll', {
    from: accounts[0],
    deterministicDeployment: true,
    args: [config.network.entryPointAddress],
    log: true,
  });

  // Amount of ETH you want to send to the contract as part of the deposit
  const amountToSend = ethers.utils.parseEther("0.2"); // Sending 1 ETH, adjust as needed

  // Interact with the deployed contract to call deposit() 
  const Paymaster = await ethers.getContractFactory("TestPaymasterAcceptAll");
  const paymasterInstance = Paymaster.attach(deployment.address);

  // Call the deposit function and send ETH in the same transaction
  await paymasterInstance.connect(ethers.provider.getSigner(accounts[0])).deposit({
    value: amountToSend
  });

  console.log(`Sent ${ethers.utils.formatEther(amountToSend)} ETH to ${deployment.address} by calling deposit()`);
};

export default func;

