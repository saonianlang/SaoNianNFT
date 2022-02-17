const {ethers, upgrades} = require('hardhat');

async function main() {
    const NFT = await ethers.getContractFactory('NFT');
    await upgrades.upgradeProxy('0x02dd14a536f55db7d4a71a0bbf302251cb1155df', NFT, [4]);
    console.log('NFT Contract update success');
}

main();
