import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import './tasks/check-images';
import './tasks/generate-assets';
import './tasks/ipfs-cid';
import './tasks/ipfs-upload-file';
import './tasks/placeholder';
import './tasks/reveal';
import './tasks/opensea-proxy-address';
import './tasks/whitelist';
const config: HardhatUserConfig = {
  solidity: '0.8.24',
};

export default config;
