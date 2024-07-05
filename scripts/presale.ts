import { readFileSync } from 'fs';
import hre, { network } from 'hardhat';
import { MetaDogPresale } from '../ignition/modules/main';

async function main() {
  const collectionExists = await run('check-images');

  if (!collectionExists) {
    throw new Error('You have not created any assets.');
  }
  const chainIdHex = await network.provider.send('eth_chainId');
  const chainId = String(parseInt(chainIdHex, 16));

  const whitelist: {
    root: string;
    proofs: string[];
  } = JSON.parse(readFileSync('./assets/generated/whitelist.json', 'utf8'));

  try {
    const jsonData = JSON.parse(
      readFileSync(
        `./ignition/deployments/chain-${chainId}/deployed_addresses.json`,
        'utf8'
      )
    );
    const address = jsonData['MetaDogModule#MetaDog'];
    const { metadog } = await hre.ignition.deploy(MetaDogPresale, {
      parameters: {
        MetaDogPresale: { address: address, whitelistRoot: whitelist.root },
      },
    });
  } catch (err) {
    console.error('Error:', err);
  }
}

main().catch(console.error);
