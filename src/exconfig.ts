import { EVMNetwork } from './pages/Background/types/network';

// eslint-disable-next-line import/no-anonymous-default-export
export default {
  enablePasswordEncryption: false,
  showTransactionConfirmationScreen: true,
  factory_address: '0xcb9E5Df70EBa6513621D2941a93fBAaD191b73d4',
  stateVersion: '0.1',
  network: {
    chainID: '5',
    family: 'EVM',
    name: 'Goerli',
    provider: 'https://goerli.infura.io/v3/1127cec9325243eb9b36471bdcff29d1',
    entryPointAddress: '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789',
    bundler: 'https://api.blocknative.com/v1/goerli/bundler',
    baseAsset: {
      symbol: 'ETH',
      name: 'ETH',
      decimals: 18,
      image:
        'https://ethereum.org/static/6b935ac0e6194247347855dc3d328e83/6ed5f/eth-diamond-black.webp',
    },
  } satisfies EVMNetwork,
};
