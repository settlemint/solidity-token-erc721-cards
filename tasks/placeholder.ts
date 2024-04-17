import { mkdirSync, readdirSync, readFileSync, writeFileSync } from 'fs';
import { task } from 'hardhat/config';
import chalk from 'chalk';

task('placeholder', 'Sets up the metadata and image for the pre-reveal stage')
  .addParam<string>('ipfsnode', 'the key of the ipfs node to use')
  .setAction(async ({ ipfsnode }: { ipfsnode: string }, hre) => {
    const images = readdirSync(`./assets/generated/cards/`)
      .filter((subject) => subject.includes('.png'))
      .map((subject) => {
        return subject.replace(/\.[^/.]+$/, '');
      });

    console.log('');
    console.log(
      chalk.gray.dim(
        '--------------------------------------------------------------------------'
      )
    );
    console.log(
      `Preparing ${chalk.yellow.bold(
        images.length
      )} placeholders for the pre-reveal stage:`
    );

    const imageCID: string = await hre.run('ipfs-upload-file', {
      sourcepath: './assets/placeholder/placeholder.png',
      ipfspath: '/metadog-placeholder/placeholder.png',
      ipfsnode,
    });
    console.log(
      `  Placeholder image: ${chalk.green.bold(`ipfs://${imageCID}`)}`
    );

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
        ipfsnode,
      });
    }
    console.log(`  Uploading metadata: ${chalk.green.bold(`DONE`)}`);

    const folderCID: string = await hre.run('ipfs-cid', {
      ipfspath: `/metadog-placeholder`,
      ipfsnode,
    });
    console.log(`  baseTokenURI: ${chalk.green.bold(`ipfs://${folderCID}`)}`);

    console.log(
      chalk.gray.dim(
        '--------------------------------------------------------------------------'
      )
    );
    console.log('');

    return folderCID;
  });
