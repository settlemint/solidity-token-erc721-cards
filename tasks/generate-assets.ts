import { createCanvas, loadImage, registerFont } from "canvas";
import { mkdirSync, readFileSync, readdirSync, writeFileSync } from "fs";
import { task, types } from "hardhat/config";
import sizeOf from "image-size";
import shuffle from "lodash/shuffle";
import { join } from "path";
import sharp from "sharp";

task("generate-assets", "Generates everything needed to reveal")
  .addParam<number>("common", "the amount of commons to generate", 1, types.int)
  .addParam<number>(
    "limited",
    "the amount of limited to generate",
    1,
    types.int
  )
  .addParam<number>("rare", "the amount of limited to generate", 1, types.int)
  .addParam<number>("unique", "the amount of limited to generate", 1, types.int)
  .setAction(
    async (
      {
        common,
        limited,
        rare,
        unique,
      }: {
        common: number;
        limited: number;
        rare: number;
        unique: number;
      },
      hre
    ) => {
      const subjects = readdirSync("./assets/layers/subjects/")
        .filter((subject) => subject.includes(".png"))
        .map((subject) => {
          return subject.replace(/\.[^/.]+$/, "");
        });

      const toRandomize = [];

      for (const subject of subjects) {
        for (let commonIndex = 1; commonIndex <= common; commonIndex++) {
          toRandomize.push({
            subject,
            rarity: "common",
            cardindex: commonIndex,
            totalcards: common,
          });
        }
        for (let limitedIndex = 1; limitedIndex <= limited; limitedIndex++) {
          toRandomize.push({
            subject,
            rarity: "limited",
            cardindex: limitedIndex,
            totalcards: common,
          });
        }
        for (let rareIndex = 1; rareIndex <= rare; rareIndex++) {
          toRandomize.push({
            subject,
            rarity: "rare",
            cardindex: rareIndex,
            totalcards: common,
          });
        }
        for (let uniqueIndex = 1; uniqueIndex <= unique; uniqueIndex++) {
          toRandomize.push({
            subject,
            rarity: "unique",
            cardindex: uniqueIndex,
            totalcards: unique,
          });
        }
      }

      const randomized = shuffle(toRandomize);

      let index = 1;
      for (const { subject, rarity, cardindex, totalcards } of randomized) {
        const imageCID: string = await hre.run("generate-asset", {
          subject,
          rarity,
          cardindex,
          totalcards,
          tokenId: index,
        });

        const metadata = JSON.parse(
          readFileSync(`./assets/metadata/${subject}.json`, "utf8")
        );

        const finalMetadata = {
          ...metadata,
          name: `${metadata.name} (#${cardindex}/${totalcards})`,
          image: `ipfs://${imageCID}`,
          attributes: [
            ...metadata.attributes,
            {
              trait_type: "Rarity",
              value: rarity,
            },
          ],
        };

        writeFileSync(
          `./assets/generated/cards/${index}.json`,
          JSON.stringify(finalMetadata, null, 2)
        );

        await hre.run("ipfs-upload-file", {
          sourcepath: `./assets/generated/cards/${index}.json`,
          ipfspath: `/metadog/${index}.json`,
        });

        index++;
      }
    }
  );

task("generate-asset", "Generates a card image")
  .addParam<string>(
    "subject",
    "the name of the subject as used in the filename in the subjects folder"
  )
  .addParam<string>("rarity", "the rarity of the card")
  .addParam<number>(
    "cardindex",
    "index for this card for this rarity",
    1,
    types.int
  )
  .addParam<number>(
    "totalcards",
    "amount of cards per dog for this rarity",
    10,
    types.int
  )
  .addParam<number>("tokenId", "the token id for this card", 1, types.int)
  .setAction(
    async (
      {
        subject,
        rarity,
        cardindex,
        totalcards,
        tokenId,
      }: {
        subject: string;
        rarity: string;
        cardindex: number;
        totalcards: number;
        tokenId: number;
      },
      hre
    ) => {
      console.log(
        `Created edition: ${tokenId}, with DNA: ${subject} @ ${rarity} (${cardindex}/${totalcards})`
      );

      // create the directory structure
      mkdirSync("./assets/generated/cards", { recursive: true });

      // register the fonts
      registerFont(`./assets/layers/fonts/NotoSansMono-Medium.ttf`, {
        family: "NotoSansMono",
        weight: "normal",
        style: "normal",
      });
      registerFont(`./assets/layers/fonts/PublicSans-Bold.ttf`, {
        family: "PublicSans",
        weight: "bold",
        style: "normal",
      });
      registerFont(`./assets/layers/fonts/PublicSans-Medium.ttf`, {
        family: "PublicSans",
        weight: "normal",
        style: "normal",
      });

      // get the background image dimensions
      const backgroundDimensions = sizeOf(
        join("./assets/layers/backgrounds", `${rarity}.png`)
      );
      if (!backgroundDimensions.width || !backgroundDimensions.height) {
        throw new Error("Could not get the dimensions of the image");
      }

      // setup the canvas
      const artMax = 700;
      const isWide =
        backgroundDimensions.height / backgroundDimensions.width < 1;
      const width = Math.round(
        isWide
          ? artMax
          : (backgroundDimensions.width / backgroundDimensions.height) * artMax
      );
      const height = Math.round(
        isWide
          ? (backgroundDimensions.height / backgroundDimensions.width) * artMax
          : artMax
      );
      const canvas = createCanvas(width, height);
      const ctx = canvas.getContext("2d");

      // base background color
      ctx.fillStyle = "white";
      ctx.fillRect(0, 0, width, height);

      // draw background
      const backgroundImage = await loadImage(
        join("./assets/layers/backgrounds", `${rarity}.png`)
      );
      ctx.drawImage(
        backgroundImage,
        0,
        0,
        backgroundDimensions.width,
        backgroundDimensions.height,
        0,
        0,
        width,
        height
      );

      // get the subject image dimensions
      const subjectDimensions = sizeOf(
        join("./assets/layers/subjects", `${subject}.png`)
      );
      if (!subjectDimensions.width || !subjectDimensions.height) {
        throw new Error("Could not get the dimensions of the image");
      }

      // draw subject
      const subjectImage = await loadImage(
        join("./assets/layers/subjects", `${subject}.png`)
      );
      ctx.drawImage(
        subjectImage,
        0,
        0,
        subjectDimensions.width,
        subjectDimensions.height,
        0,
        0,
        width,
        height
      );

      // get the overlay image dimensions
      const overlayDimensions = sizeOf(
        join("./assets/layers/overlays", `${rarity}.png`)
      );
      if (!overlayDimensions.width || !overlayDimensions.height) {
        throw new Error("Could not get the dimensions of the image");
      }

      // draw overlay
      const overlayImage = await loadImage(
        join("./assets/layers/overlays", `${rarity}.png`)
      );
      ctx.drawImage(
        overlayImage,
        0,
        0,
        overlayDimensions.width,
        overlayDimensions.height,
        0,
        0,
        width,
        height
      );

      const metadata = JSON.parse(
        readFileSync(`./assets/metadata/${subject}.json`, "utf8")
      );

      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillStyle = "white";
      ctx.font = `bold 60px PublicSans`;
      ctx.fillText(metadata.name, Math.round(width / 2), 480);

      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillStyle = "white";
      ctx.font = `normal 20px NotoSansMono`;
      ctx.fillText(`#${cardindex}/${totalcards}`, Math.round(width / 2), 530);

      ctx.textAlign = "end";
      ctx.textBaseline = "middle";
      ctx.fillStyle = "white";
      ctx.font = `normal 20px PublicSans`;
      ctx.fillText(
        metadata.attributes.find(
          (attr: { trait_type: string; value: string }) =>
            attr.trait_type === "Breed"
        )?.value,
        width - 20,
        30
      );

      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillStyle = "white";
      ctx.font = `normal 10px PublicSans`;
      ctx.fillText("SHEDDING", 60, 590);

      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillStyle = "white";
      ctx.font = `normal 30px NotoSansMono`;
      ctx.fillText(
        `${
          metadata.attributes.find(
            (attr: { trait_type: string; value: string }) =>
              attr.trait_type === "Shedding"
          )?.value
        }/5`,
        60,
        630
      );

      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillStyle = "white";
      ctx.font = `normal 10px PublicSans`;
      ctx.fillText("AFFECTIONATE", Math.round(width / 2), 590);

      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillStyle = "white";
      ctx.font = `normal 30px NotoSansMono`;
      ctx.fillText(
        `${
          metadata.attributes.find(
            (attr: { trait_type: string; value: string }) =>
              attr.trait_type === "Affectionate"
          )?.value
        }/5`,
        Math.round(width / 2),
        630
      );

      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillStyle = "white";
      ctx.font = `normal 10px PublicSans`;
      ctx.fillText("PLAYFULNESS", 360, 590);

      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillStyle = "white";
      ctx.font = `normal 30px NotoSansMono`;
      ctx.fillText(
        `${
          metadata.attributes.find(
            (attr: { trait_type: string; value: string }) =>
              attr.trait_type === "Playfulness"
          )?.value
        }/5`,
        360,
        630
      );

      // save image
      await sharp(
        canvas.toBuffer("image/png", {
          compressionLevel: 0,
          filters: canvas.PNG_FILTER_NONE,
        })
      )
        .png({ compressionLevel: 4 })
        .toFile(`./assets/generated/cards/${tokenId}.png`);

      return await hre.run("ipfs-upload-file", {
        sourcepath: `./assets/generated/cards/${tokenId}.png`,
        ipfspath: `/metadog/${tokenId}.png`,

      });
    }
  );
