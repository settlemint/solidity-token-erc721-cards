import hre from 'hardhat';
import { default as MetaDogModule } from '../ignition/modules/main';

import { network } from 'hardhat';

async function main() {
  const chainIdHex = await network.provider.send('eth_chainId');
  const chainId = String(parseInt(chainIdHex, 16));

  const proxyaddress = await run('opensea-proxy-address', {
    chainid: chainId,
  });

  await run('generate-assets');

  const placeholder: string = await run('placeholder', {
    amount: 1,
  });
  const { metadog } = await hre.ignition.deploy(MetaDogModule, {
    parameters: {
      MetaDogModule: { placeholder: placeholder, proxyaddress: proxyaddress },
    },
  });
  console.log('Contract deployed');
}

main().catch(console.error);
