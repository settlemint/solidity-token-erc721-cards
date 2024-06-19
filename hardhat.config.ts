import '@nomicfoundation/hardhat-foundry';
import '@nomicfoundation/hardhat-toolbox';
import '@nomiclabs/hardhat-solhint';
import type { HardhatUserConfig } from 'hardhat/config';
import './tasks/check-images';
import './tasks/generate-assets';
import './tasks/ipfs-cid';
import './tasks/ipfs-upload-file';
import './tasks/opensea-proxy-address';
import './tasks/placeholder';
import './tasks/reveal';
import './tasks/whitelist';

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.26',
    settings: {
      optimizer: {
        enabled: true,
        runs: 10_000,
      },
    },
  },
  networks: {
    hardhat: {},
    btp: {
      url: process.env.BTP_RPC_URL || '',
      gasPrice: process.env.BTP_GAS_PRICE
        ? parseInt(process.env.BTP_GAS_PRICE)
        : 'auto',
    },
  },
};

export default config;
