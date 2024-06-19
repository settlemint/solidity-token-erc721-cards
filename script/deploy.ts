import hre from 'hardhat';
import { MetaDogModule } from '../ignition/modules/MetaDog';

import { network } from 'hardhat';

async function main() {
  const chainIdHex = await network.provider.send('eth_chainId');
  const chainId = String(parseInt(chainIdHex, 16));

  const proxyaddress = await run('opensea-proxy-address', {
    chainid: chainId,
  });

  await run('generate-assets', {});

  const placeholder: string = await run('placeholder', {
    amount: 1,
  });
  const { metadog } = await hre.ignition.deploy(MetaDogModule, {
    parameters: {
      MetaDogModule: { placeholder: placeholder, proxyaddress: proxyaddress },
    },
  });
}

main().catch(console.error);
