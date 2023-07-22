import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import config from '../src/exconfig';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const accounts = await hre.getUnnamedAccounts();
  console.log(config.network.entryPointAddress)
  await hre.deployments.deploy('SimpleAccountFactory', {
    from: accounts[0],
    deterministicDeployment: true,
    args: [config.network.entryPointAddress],
    log: true,
  });
};
export default func; 
