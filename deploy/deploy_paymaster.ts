import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import config from '../src/exconfig';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, ethers } = hre;
  const accounts = await hre.getUnnamedAccounts();

  const wETH_addr = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6";
  const UNI_Router_addr = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";

  const deployment = await deployments.deploy('Paymaster', {
    from: accounts[0],
    deterministicDeployment: true,
    args: [
      config.network.entryPointAddress,
      accounts[0],
      [40000, 1e6, 1e6, UNI_Router_addr, wETH_addr]
    ],
    log: true,
  });


  /*** Make a deposit to EntryPoint for the paymaster ***/
  // Amount of ETH you want to send to the contract as part of the deposit
  const amountToSend = ethers.utils.parseEther("0.2"); // adjust as needed

  // Interact with the deployed contract to call deposit() 
  const Paymaster = await ethers.getContractFactory("Paymaster");
  const paymasterInstance = Paymaster.attach(deployment.address);

  // Call the deposit function with attached ETH
  await paymasterInstance.connect(ethers.provider.getSigner(accounts[0])).deposit({
    value: amountToSend
  });

  console.log(`Deposited ${ethers.utils.formatEther(amountToSend)} ETH for Paymaster ${deployment.address} by calling deposit()`);


  /*** Configure the paymaster ***/
  // // Allow the extcodehash of the wallet
  // updateAllowedByteCode(bytes32 _byteCodeHash = ???, bool _isAllowed = true);

  // // Allow the desired functions
  // updateAllowedDiscrim(uint32 _discrim, bool _isAllowed = true);
  // updateAllowedDiscrim(uint32 _discrim, bool _isAllowed = true);
  // updateAllowedDiscrim(uint32 _discrim, bool _isAllowed = true);

  // // Tell Paymaster to fetch price from oracle for the desired ERC-20 tokens
  // updateCachedRate(address token); //wETH "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
  // updateCachedRate(address token); //UNI

  // (await ethers.getContractFactory("Paymaster")).attach()
};

export default func;

