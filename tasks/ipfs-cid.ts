import { task } from "hardhat/config";
import { create } from "ipfs-http-client";

task("ipfs-cid", "Gets a CID on IPFS for a path")
  .addParam<string>("ipfspath", "the path")
  .setAction(async ({ ipfspath }: { ipfspath: string }) => {
    const env = await fetch(
      `${process.env.BTP_CLUSTER_MANAGER_URL}/ide/foundry/${process.env.BTP_SCS_ID}/env`,
      {
        headers: {
          "x-auth-token": process.env.BTP_SERVICE_TOKEN!,
        },
      }
    );

    const envText = await env.text();

    const envVars = envText.split("\n").map((line) => line.trim());
    for (const envVar of envVars) {
      const [key, value] = envVar.split("=");
      process.env[key] = value;
    }

    const btpIpfs = process.env.BTP_IPFS;

    if (!btpIpfs) {
      throw new Error(`No IPFS node found or configured wrong.`);
    }
    const lastSlashIndex = btpIpfs.lastIndexOf("/");
    const baseUrl = btpIpfs.substring(0, lastSlashIndex);

    const ipfsClient = create({
      url: baseUrl,
      headers: {
        "x-auth-token": process.env.BTP_SERVICE_TOKEN!,
      },
    });

    const { cid } = await ipfsClient.files.stat(ipfspath);
    return cid.toString();
  });
