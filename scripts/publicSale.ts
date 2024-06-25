import { readFileSync } from 'fs';
import hre, { network } from 'hardhat';
import { MetaDogPublicSale } from '../ignition/modules/MetaDog';

async function main() {
  const collectionExists = await run('check-images');

  if (!collectionExists) {
    throw new Error('You have not created any assets.');
  }
  const chainIdHex = await network.provider.send('eth_chainId');
  const chainId = String(parseInt(chainIdHex, 16));

  try {
    const jsonData = JSON.parse(
      readFileSync(
        `./ignition/deployments/chain-${chainId}/deployed_addresses.json`,
        'utf8'
      )
    );
    const address = jsonData['MetaDogModule#MetaDog'];
    const { metadog } = await hre.ignition.deploy(MetaDogPublicSale, {
      parameters: {
        MetaDogPublicSale: { address: address },
      },
    });
  } catch (err) {
    console.error('Error:', err);
  }
}

main().catch(console.error);
