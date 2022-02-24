// const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("NFT", function () {
    it("test deploy contract", async function () {
        const NFT = await ethers.getContractFactory("NFT");
        const nft = await NFT.deploy();
        await nft.deployed();
        console.log("NFT deployed to:", nft.address);
    });
});
