import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const accounts = await hre.getUnnamedAccounts();
  await hre.deployments.deploy('SimpleAccount', {
    from: accounts[0],
    deterministicDeployment: true,
    args: ['0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789'],
    log: true,
  });
};
export default func;
