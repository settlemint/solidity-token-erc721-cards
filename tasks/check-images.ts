import { readdirSync } from 'fs';
import { task } from 'hardhat/config';

task('check-images', 'Checks if images have been generated').setAction(
  async () => {
    const images = readdirSync(`./assets/generated/cards/`)
      .filter((subject) => subject.includes('.png'))
      .map((subject) => {
        return subject.replace(/\.[^/.]+$/, '');
      });
    console.log(images.length > 0);
    return images.length > 0;
  }
);
