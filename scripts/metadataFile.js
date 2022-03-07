const fs = require("fs");

const metadataJson = {
    description: "Grape music issuance test NFT album",
    external_url: "https://twitter.com/saonian15",
    image: "https://gateway.pinata.cloud/ipfs/QmeUNtQAMTapBSBdsKs1yHvgTTRbffs2LAPh2bK1EaTixU",
    name: "Grape Music NFT",
    animation_url: "https://gateway.pinata.cloud/ipfs/QmdXX1eXKN7mycrxc1faAAhHxnSF3nGDS8u773qcF15vGq",
    attributes: [
        {
            trait_type: "Song",
            value: "Song Name 1",
        },
        {
            trait_type: "Song",
            value: "Song Name 2",
        },
        {
            trait_type: "Song",
            value: "Song Name 3",
        },
        {
            trait_type: "Song",
            value: "Song Name 4",
        },
    ],
};

const fileCount = 100;

function setFile(data, index) {
    try {
        fs.writeFileSync(`/Users/saonian/区块链/工程/SaoNianNFT/metadataFile/${index}.json`, JSON.stringify(data));
    } catch (err) {
        console.error(err);
    }
}

for (let index = 0; index < fileCount; index++) {
    setFile(metadataJson, index + 1);
}
