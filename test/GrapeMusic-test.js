const {expect} = require("chai");
const {ethers, deployments} = require("hardhat");

describe("GrapeMusic", function () {
    let grapeMusic, deployer, alice;
    const publicSaleKey = "abc123";

    before(async () => {
        await deployments.fixture(); // ensure we start from a fresh deployments
        [deployer, alice] = await ethers.getSigners();
        grapeMusic = await ethers.getContract("GrapeMusic");
    });

    it("test initialization contract parameters", async function () {
        await grapeMusic.setupSaleInfo(0.01, 0.05, "1583251200");
        await grapeMusic.setPublicSaleKey(publicSaleKey);
        await grapeMusic.seedAllowlist(["0xFed0Eb2159fC3E13d74DBc9Dc346488268ad997d", "0x64339fb21E0D36f5CCC306dfab8e8bEeaB4DF70C"], [1, 2]);
        await grapeMusic.setBaseURI("https://gateway.pinata.cloud/ipfs/QmeqPf8CmUBTZZu8Kh6dFtFnuDietsnDczJb3kjEJ8YnJQ");
        await grapeMusic.setDefaultRoyalty("0xFed0Eb2159fC3E13d74DBc9Dc346488268ad997d", 5);
    });

    it("test verify common quantity", async function () {});
});
