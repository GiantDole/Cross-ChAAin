import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import config from '../src/exconfig';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, ethers } = hre;
  const accounts = await hre.getUnnamedAccounts();

  const deployment = await deployments.deploy('Paymaster', {
    from: accounts[0],
    deterministicDeployment: true,
    args: [config.network.entryPointAddress],
    log: true,
  });

  // Amount of ETH you want to send to the contract
  const amountToSend = ethers.utils.parseEther("1"); // Sending 1 ETH, adjust as needed

  // Signer for the deploying account
  const signer = ethers.provider.getSigner(accounts[0]);

  // Sending ETH to the deployed contract
  await signer.sendTransaction({
    to: deployment.address,
    value: amountToSend,
  });

  // Interact with the deployed contract to call deposit() 
  const Paymaster = await ethers.getContractFactory("Paymaster");
  const paymasterInstance = Paymaster.attach(deployment.address);

  await paymasterInstance.connect(signer).deposit({
    value: amountToSend
  });

  console.log(`Sent ${ethers.utils.formatEther(amountToSend)} ETH to ${deployment.address} and called deposit()`);
};

export default func;
