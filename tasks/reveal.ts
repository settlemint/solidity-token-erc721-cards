import { task } from 'hardhat/config';

task('reveal', 'Generates everything needed to reveal')
  .addParam<string>('ipfsnode', 'the key of the ipfs node to use')
  .setAction(
    async (
      {
        ipfsnode,
      }: {
        ipfsnode: string;
      },
      hre
    ) => {
      const folderCID: string = await hre.run('ipfs-cid', {
        ipfspath: `/metadog`,
        ipfsnode,
      });

      return folderCID;
    }
  );
