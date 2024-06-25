import chalk from 'chalk';
import { mkdirSync, readdirSync, readFileSync, writeFileSync } from 'fs';
import { task } from 'hardhat/config';

task(
  'placeholder',
  'Sets up the metadata and image for the pre-reveal stage'
).setAction(async ({}: {}, hre) => {
  const images = readdirSync(`./assets/generated/cards/`)
    .filter((subject) => subject.includes('.png'))
    .map((subject) => {
      return subject.replace(/\.[^/.]+$/, '');
    });

  const imageCID: string = await hre.run('ipfs-upload-file', {
    sourcepath: './assets/placeholder/placeholder.png',
    ipfspath: '/metadog-placeholder/placeholder.png',
  });
  console.log(`  Placeholder image: ${chalk.green.bold(`ipfs://${imageCID}`)}`);

  const metadata = JSON.parse(
    readFileSync('./assets/placeholder/placeholder.json', 'utf8')
  );
  metadata.image = `ipfs://${imageCID}`;
  mkdirSync('./assets/generated/', { recursive: true });
  writeFileSync(
    './assets/generated/placeholder.json',
    JSON.stringify(metadata, null, 2)
  );

  for (let i = 1; i <= images.length; i++) {
    await hre.run('ipfs-upload-file', {
      sourcepath: './assets/generated/placeholder.json',
      ipfspath: `/metadog-placeholder/${i}.json`,
    });
  }

  const folderCID: string = await hre.run('ipfs-cid', {
    ipfspath: `/metadog-placeholder`,
  });

  return folderCID;
});
