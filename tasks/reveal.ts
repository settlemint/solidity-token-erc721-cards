import { task } from 'hardhat/config';

task('reveal', 'Generates everything needed to reveal').setAction(
  async ({}: {}, hre) => {
    const folderCID: string = await hre.run('ipfs-cid', {
      ipfspath: `/metadog`,
    });
    return folderCID;
  }
);
