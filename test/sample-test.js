const {expect} = require('chai');
const {ethers} = require('hardhat');

describe('NFT', function () {
    it("Should return the new greeting once it's changed", async function () {
        const NFT = await ethers.getContractFactory('NFT');
        const nft = await NFT.deploy('Hello, world!');
        await nft.deployed();

        expect(await nft.greet()).to.equal('Hello, world!');

        const setGreetingTx = await nft.setGreeting('Hola, mundo!');

        // wait until the transaction is mined
        await setGreetingTx.wait();

        expect(await nft.greet()).to.equal('Hola, mundo!');
    });
});
