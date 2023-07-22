import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const accounts = await hre.getUnnamedAccounts();
  await hre.deployments.deploy('SimpleAccount', {
    from: accounts[0],
    deterministicDeployment: true,
    args: ['0x0576a174D229E3cFA37253523E645A78A0C91B57'],
    log: true,
  });
};
export default func;
