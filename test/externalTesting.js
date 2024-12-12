const { ethers, network } = require("hardhat");
const { expect } = require("chai");

describe("WABBIT Phase 4 Test", function () {
  let WABBIT, wabbit, owner, addr1, addr2, whitelistMock;

  beforeEach(async function () {
    // Deploy a mock whitelist contract
    const WhitelistMock = await ethers.getContractFactory("WhitelistMock");
    whitelistMock = await WhitelistMock.deploy(); // Deploy the mock contract
    // await whitelistMock.deployed();

    // Deploy the WABBIT contract
    WABBIT = await ethers.getContractFactory("WABBIT");
    [owner, addr1, addr2] = await ethers.getSigners();

    wabbit = await WABBIT.deploy(); // Deploy the WABBIT contract
    // await wabbit.deployed();

    // Set the whitelist checker to the mock contract
    await wabbit.addWLChecker(whitelistMock.target);

    // Set the current timestamp and configure start time
    const currentTime = Math.floor(Date.now() / 1000); // Current time in seconds
    const startTime = currentTime + 10; // Start time 10 seconds from now

    await wabbit.setStartTime(startTime); // Set the start time for the contract

    // Advance time by 2 hours (7200 seconds) to simulate Phase 4
    await network.provider.send("evm_increaseTime", [7200]); // Advance 2 hours
    await network.provider.send("evm_mine"); // Mine a new block to apply the time change
  });

  it("should not make external calls during Phase 4", async function () {
    // Confirm that we are in Phase 4
    const phase = await wabbit.tradingPhase();
    expect(phase).to.equal(4);

    // Perform a transfer to trigger the `_update` function
    const transferAmount = ethers.parseUnits("1", 18);
    await wabbit.transfer(addr1.address, transferAmount);

    // Check if the mock whitelist contract was called
    const wasCalled = await whitelistMock.wasCalled();
    expect(wasCalled).to.equal(false); // Must remain false in Phase 4
  });
});
