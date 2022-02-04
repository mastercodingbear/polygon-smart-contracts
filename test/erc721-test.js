/* eslint-disable node/no-unsupported-features/es-builtins */
/* eslint-disable no-unused-vars */
/* eslint-disable no-undef */
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@openzeppelin/test-helpers");
const R = require("ramda");

const cyan = "\x1b[36m%s\x1b[0m";
const yellow = "\x1b[33m%s\x1b[0m";

const formatEthers = (stringValue) => ethers.utils.formatUnits(stringValue, 18);

const displayChildsOfParent = (data) =>
  R.map((single) => single?.toString())(data);

describe.only("OVRLand ERC721 - TEST", async () => {
  let OVRLand, ovrLand;
  let OVRLandContainer, ovrLandContainer;
  let OVRMarketplace, ovrMarketplace;
  let ovrToken;
  let uniswap;
  const provider = ethers.getDefaultProvider();

  const ovrAddress = "0x21bfbda47a0b4b5b1248c767ee49f7caa9b23697";
  const uniswapRoterAddress = "0xf164fC0Ec4E93095b804a4795bBe1e041497b92a";

  beforeEach(async () => {
    OVRLand = await ethers.getContractFactory("OVRLand");
    OVRLandContainer = await ethers.getContractFactory("OVRLandContainer");
    OVRMarketplace = await ethers.getContractFactory("OVRMarketplace");
    [
      owner, // 50 ether
      addr1, // 0
      addr2, // 0
      addr3, // 0
      addr4, // 0
      addr5, // 0
      addr6, // 0
      addr7, // 0
      addr8, // 0
      addr9, // 0
      addr10, // 0
      addr11, // 0
      addr12, // 0
      addr13, // 0
      addr14, // 0
      addr15, // 0
      addr16, // 0
      addr17, // 0
      addr18, // 1000 ether
    ] = await ethers.getSigners();
  });

  describe("OVRLandV2 Contract", () => {
    it("Should deploy", async () => {
      ovrLand = await OVRLand.deploy();
      await ovrLand.deployed();

      landAddress = ovrLand.address;
      console.debug(`\t\t\tOVRLand Contract Address: ${cyan}`, landAddress);

      ovrLandContainer = await OVRLandContainer.deploy();
      await ovrLandContainer.deployed();
      await ovrLandContainer.initialize(landAddress);
      console.debug(
        `\t\t\tOVRLandContainer Contract Address: ${cyan}`,
        ovrLandContainer.address
      );

      ovrMarketplace = await OVRMarketplace.deploy();
      await ovrMarketplace.deployed();
      await ovrMarketplace.initialize(
        ovrAddress,
        ovrLand.address,
        ovrLandContainer.address,
        500,
        owner.address
      );

      await ovrLandContainer.setMarketplaceAddress(ovrMarketplace.address);
    });

    it("Owner should mint LandID 1", async () => {
      await ovrLand.mint(owner.address, 1);
      const ownerOVRLandBalance = await ovrLand.balanceOf(owner.address);
      console.debug(
        "\t\t\tOWNER OVRLand Balance:",
        `${ownerOVRLandBalance.toString()}`
      );

      const TotalSupply = await ovrLand.totalSupply();
      console.debug("\t\t\tInitial Total Supply:", `${TotalSupply.toString()}`);

      expect(ownerOVRLandBalance.toString()).to.equal(TotalSupply);
    });

    it("Owner should mint LandID 2", async () => {
      await ovrLand.mint(owner.address, 2);
      const ownerOVRLandBalance = await ovrLand.balanceOf(owner.address);
      console.debug(
        "\t\t\tOWNER OVRLand Balance:",
        `${ownerOVRLandBalance.toString()}`
      );

      const TotalSupply = await ovrLand.totalSupply();
      console.debug("\t\t\tInitial Total Supply:", `${TotalSupply.toString()}`);

      expect(ownerOVRLandBalance.toString()).to.equal(TotalSupply);
    });

    it("Owner should mint LandID 3", async () => {
      await ovrLand.mint(owner.address, 3);
      const ownerOVRLandBalance = await ovrLand.balanceOf(owner.address);
      console.debug(
        "\t\t\tOWNER OVRLand Balance:",
        `${ownerOVRLandBalance.toString()}`
      );

      const TotalSupply = await ovrLand.totalSupply();
      console.debug("\t\t\tInitial Total Supply:", `${TotalSupply.toString()}`);

      expect(ownerOVRLandBalance.toString()).to.equal(TotalSupply);
    });

    it("Owner should mint LandID 4", async () => {
      await ovrLand.mint(owner.address, 4);
      const ownerOVRLandBalance = await ovrLand.balanceOf(owner.address);
      console.debug(
        "\t\t\tOWNER OVRLand Balance:",
        `${ownerOVRLandBalance.toString()}`
      );

      const TotalSupply = await ovrLand.totalSupply();
      console.debug("\t\t\tInitial Total Supply:", `${TotalSupply.toString()}`);

      expect(ownerOVRLandBalance.toString()).to.equal(TotalSupply);
    });

    it("Addr1 should FAIL mintLand(addr1, 5)", async () => {
      await expect(ovrLand.connect(addr1).mint(addr1.address, 5)).to.be
        .reverted;
    });

    it("Addr1 should FAIL safeMint(addr1, 5)", async () => {
      await expect(ovrLand.connect(addr1).mint(addr1.address, 5)).to.be
        .reverted;
    });

    it("Owner should set Addr1 as MINTER_ROLE", async () => {
      await expect(ovrLand.connect(owner).addMinter(addr1.address)).to.be.not
        .reverted;
    });

    it("Add2 should FAIL mint LandId 5", async () => {
      await expect(ovrLand.connect(addr2).mint(addr2.address, 5)).to.be
        .reverted;
    });

    it("Add1 should pass mint LandId 5", async () => {
      await expect(ovrLand.connect(addr1).mint(addr1.address, 5)).to.be.not
        .reverted;
    });

    it("Owner should FAIL mint LandId 5 (just minted)", async () => {
      await expect(ovrLand.connect(owner).mint(owner.address, 5)).to.be
        .reverted;
    });

    it("Owner should set Addr10 as MINTER_ROLE", async () => {
      await expect(ovrLand.connect(owner).addMinter(addr10.address)).to.be.not
        .reverted;
    });

    it("Addr10 should own 0 lands", async () => {
      const balance = await ovrLand.balanceOf(addr10.address);
      console.debug("\t\t\tAddr10 OVRLand Balance:", `${balance.toString()}`);
      expect(balance.toString()).to.equal("0");
    });

    it("Addr10 should batchMint 20 lands", async () => {
      await ovrLand
        .connect(addr10)
        .batchMintLands(
          [
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
          ],
          [
            100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112,
            113, 114, 115, 116, 117, 118, 119,
          ]
        );

      const balance = await ovrLand.balanceOf(addr10.address);
      console.debug("\t\t\tAddr10 OVRLand Balance:", `${balance.toString()}`);
      expect(balance.toString()).to.equal("20");
    });

    it("addr10 should burn landId 119, SHOULD FAIL", async () => {
      await expect(ovrLand.connect(addr10).burn(119)).to.be.reverted;
    });

    it("Owner should set Addr10 as BURNER_ROLE", async () => {
      await expect(ovrLand.addBurner(addr10.address)).to.be.not.reverted;
    });

    it("addr10 should burn landId 119", async () => {
      await expect(ovrLand.connect(addr10).burn(119)).to.be.not.reverted;
    });

    it("Owner should set Addr12 as DEFAULT_ADMIN_ROLE", async () => {
      await expect(ovrLand.connect(owner).addAdminRole(addr12.address)).to.be
        .not.reverted;
    });

    it("Addr12 should set Addr13 as DEFAULT_ADMIN_ROLE", async () => {
      await expect(ovrLand.connect(addr12).addAdminRole(addr13.address)).to.be
        .not.reverted;
    });

    it("Addr13 should addMinter Addr14 as MINTER_ROLE", async () => {
      await expect(ovrLand.connect(addr13).addMinter(addr14.address)).to.be.not
        .reverted;
    });

    it("Addr13 should addAdminRole Addr14 as MINTER_ROLE", async () => {
      await expect(ovrLand.connect(addr13).addAdminRole(addr14.address)).to.be
        .not.reverted;
    });

    it("Addr10 should approve all lands", async () => {
      await ovrLand
        .connect(addr10)
        .setApprovalForAll(ovrLandContainer.address, true);
    });

    it("Addr10 should fail creation container with land 100 to 110, and nonexistent token 1111111", async () => {
      await expect(
        ovrLandContainer
          .connect(addr10)
          .createContainer([
            100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 1111111,
          ])
      ).to.be.reverted;
    });

    it("Addr10 should create container whit land 100 to 110", async () => {
      await expect(
        ovrLandContainer
          .connect(addr10)
          .createContainer([
            100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
          ])
      ).to.be.not.reverted;
      console.log(
        "\t\t\towner of containerId 0 (first container: ",
        await ovrLandContainer.ownerOf(0)
      );
      console.log("\t\t\taddres of addr10: ", addr10.address);
    });

    it("should show lands inside the container 0", async () => {
      const lands = await ovrLandContainer.childsOfParent(0);

      console.log(displayChildsOfParent(lands));
    });

    it("addr10 should remove land 103 from the container 0", async () => {
      await ovrLandContainer.connect(addr10).removeLandFromContainer(0, 103);
      const lands = await ovrLandContainer.childsOfParent(0);
      console.log(displayChildsOfParent(lands));
    });

    it("addr10 should remove land 105 fro the container 0", async () => {
      await ovrLandContainer.connect(addr10).removeLandFromContainer(0, 105);
      const lands = await ovrLandContainer.childsOfParent(0);
      console.log(displayChildsOfParent(lands));
    });

    it("addr10 should FAIL remove land 115 the container 0", async () => {
      await expect(
        ovrLandContainer.connect(addr10).removeLandFromContainer(0, 115)
      ).to.be.reverted;
      const lands = await ovrLandContainer.childsOfParent(0);
      console.log(displayChildsOfParent(lands));
    });

    it("addr10 should add land 105 to the container 0", async () => {
      await ovrLandContainer.connect(addr10).addLandToContainer(0, 105);
      const lands = await ovrLandContainer.childsOfParent(0);
      console.log(displayChildsOfParent(lands));
    });

    it("addr10 should add land 103 to the container 0", async () => {
      await ovrLandContainer.connect(addr10).addLandToContainer(0, 103);
      const lands = await ovrLandContainer.childsOfParent(0);
      console.log(displayChildsOfParent(lands));
    });

    it("owner of land 104 (that is inside container 0) should be addr10", async () => {
      const owner = await ovrLandContainer.connect(addr10).ownerOfChild(104);
      console.log("\t\t\t", owner);
    });

    it("should delete container 0", async () => {
      await ovrLandContainer.connect(addr10).deleteContainer(0);
      await expect(ovrLandContainer.childsOfParent(0)).to.be.reverted;

      console.log("\t\t\tOwner of land 105: ", await ovrLand.ownerOf(105));
    });

    it("Addr10 should create container whit land 100, 101, 102", async () => {
      await expect(
        ovrLandContainer.connect(addr10).createContainer([100, 101, 102])
      ).to.be.not.reverted;
      console.log(
        "\t\t\tOwner of containerId 0 (first container: ",
        await ovrLandContainer.ownerOf(1)
      );
      console.log("\t\t\taddres of addr10: ", addr10.address);
      const lands = await ovrLandContainer.childsOfParent(1);
      console.log(displayChildsOfParent(lands));
    });

    it("addr10 should remove land 101 from the container 1", async () => {
      await ovrLandContainer.connect(addr10).removeLandFromContainer(1, 101);
      const lands = await ovrLandContainer.childsOfParent(1);
      console.log(displayChildsOfParent(lands));
    });

    it("addr10 should remove land 1010 from the container 1, should FAIL", async () => {
      await expect(
        ovrLandContainer.connect(addr10).removeLandFromContainer(1, 1010)
      ).to.be.reverted;

      const lands = await ovrLandContainer.childsOfParent(1);
      console.log(displayChildsOfParent(lands));
    });

    it("addr10 should remove land 100 from the container 1", async () => {
      await ovrLandContainer.connect(addr10).removeLandFromContainer(1, 100);
      await expect(ovrLandContainer.childsOfParent(1)).to.be.reverted;

      await expect(ovrLandContainer.ownerOf(1)).to.be.reverted;
      const totalSupply = await ovrLandContainer.totalSupply();
      console.log("\t\t\t", totalSupply);
    });

    it("Addr10 should create container whit land 100 to 110", async () => {
      await expect(
        ovrLandContainer
          .connect(addr10)
          .createContainer([
            100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
          ])
      ).to.be.not.reverted;
      console.log(
        "\t\t\towner of containerId 2 : ",
        await ovrLandContainer.ownerOf(2)
      );
      console.log("\t\t\taddress of addr10: ", addr10.address);
    });

    it("should create ovr and uniswap contract", async () => {
      ovrToken = await hre.ethers.getContractAt("OVR", ovrAddress);

      uniswap = await hre.ethers.getContractAt(
        "UniswapV2Router01",
        uniswapRoterAddress
      );
    });

    it("Owner Should buy", async () => {
      const path = [
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        "0x21bfbda47a0b4b5b1248c767ee49f7caa9b23697",
      ];
      const deadline = Math.floor(Date.now() / 1000) + 60 * 10;
      await uniswap
        .connect(owner)
        .swapExactETHForTokens(0, path, owner.address, deadline, {
          value: BigInt(300000000000000000),
        });

      console.debug(`\t\t\tOVR Token Contract Address: ${cyan}`, ovrAddress);

      const balance = await provider.getBalance(owner.address);
      const ovrBalance = await ovrToken.balanceOf(owner.address);
      console.debug(`\t\t\tOWNER Address: ${yellow}`, owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
      console.debug(
        "\t\t\tOWNER OVR Balance:",
        formatEthers(ovrBalance.toString())
      );
    });

    it("Addr1 Should buy", async () => {
      const path = [
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        "0x21bfbda47a0b4b5b1248c767ee49f7caa9b23697",
      ];
      const deadline = Math.floor(Date.now() / 1000) + 60 * 10;
      await uniswap
        .connect(addr1)
        .swapExactETHForTokens(0, path, addr1.address, deadline, {
          value: BigInt(300000000000000000),
        });

      console.debug(`\t\t\tOVR Token Contract Address: ${cyan}`, ovrAddress);

      const balance = await provider.getBalance(owner.address);
      const ovrBalance = await ovrToken.balanceOf(owner.address);
      console.debug(`\t\t\tOWNER Address: ${yellow}`, owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
      console.debug(
        "\t\t\tOWNER OVR Balance:",
        formatEthers(ovrBalance.toString())
      );
    });

    it("Addr2 Should buy", async () => {
      const path = [
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        "0x21bfbda47a0b4b5b1248c767ee49f7caa9b23697",
      ];
      const deadline = Math.floor(Date.now() / 1000) + 60 * 10;
      await uniswap
        .connect(addr2)
        .swapExactETHForTokens(0, path, addr2.address, deadline, {
          value: BigInt(300000000000000000),
        });

      console.debug(`\t\t\tOVR Token Contract Address: ${cyan}`, ovrAddress);

      const balance = await provider.getBalance(owner.address);
      const ovrBalance = await ovrToken.balanceOf(owner.address);
      console.debug(`\t\t\tOWNER Address: ${yellow}`, owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
      console.debug(
        "\t\t\tOWNER OVR Balance:",
        formatEthers(ovrBalance.toString())
      );
    });

    it("Addr10 Should buy", async () => {
      const path = [
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        "0x21bfbda47a0b4b5b1248c767ee49f7caa9b23697",
      ];
      const deadline = Math.floor(Date.now() / 1000) + 60 * 10;
      await uniswap
        .connect(addr10)
        .swapExactETHForTokens(0, path, addr2.address, deadline, {
          value: BigInt(300000000000000000),
        });

      console.debug(`\t\t\tOVR Token Contract Address: ${cyan}`, ovrAddress);

      const balance = await provider.getBalance(owner.address);
      const ovrBalance = await ovrToken.balanceOf(owner.address);
      console.debug(`\t\t\tOWNER Address: ${yellow}`, owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
      console.debug(
        "\t\t\tOWNER OVR Balance:",
        formatEthers(ovrBalance.toString())
      );
    });

    it("addresses should approve", async () => {
      await ovrToken.approve(ovrMarketplace.address, "5555555555");
      await ovrLand.setApprovalForAll(ovrMarketplace.address, true);
      await ovrLandContainer.setApprovalForAll(ovrMarketplace.address, true);

      await ovrToken
        .connect(addr1)
        .approve(ovrMarketplace.address, "5555555555");
      await ovrLand
        .connect(addr1)
        .setApprovalForAll(ovrMarketplace.address, true);
      await ovrLandContainer
        .connect(addr1)
        .setApprovalForAll(ovrMarketplace.address, true);

      await ovrToken
        .connect(addr2)
        .approve(ovrMarketplace.address, "5555555555");
      await ovrLand
        .connect(addr2)
        .setApprovalForAll(ovrMarketplace.address, true);
      await ovrLandContainer
        .connect(addr2)
        .setApprovalForAll(ovrMarketplace.address, true);

      await ovrToken
        .connect(addr10)
        .approve(ovrMarketplace.address, "5555555555");
      await ovrLand
        .connect(addr10)
        .setApprovalForAll(ovrMarketplace.address, true);
      await ovrLandContainer
        .connect(addr10)
        .setApprovalForAll(ovrMarketplace.address, true);
    });

    it("addr10 should sell land 111", async () => {
      await ovrMarketplace.connect(addr10).sell(111, 1000);
      const view = await ovrMarketplace.sellView(111);
      console.debug("\t\t\tview:", view.toString());
    });

    it("addr1 should change sell price nft land id 111, SHOULD FAIL", async () => {
      await expect(ovrMarketplace.connect(addr1).updatePriceLand(111, 4000)).to
        .be.reverted;
    });

    it("addr10 should change sell price nft container id 111", async () => {
      await ovrMarketplace.connect(addr10).updatePriceLand(111, 4000);
    });

    it("addr1 should buy nft id 111", async () => {
      await ovrMarketplace.connect(addr1).buy(111);

      const ownerof = await ovrLand.ownerOf(111);
      console.debug("\t\t\taddress 1 address:", addr1.address);
      console.debug("\t\t\towner of land 0:", ownerof);
    });

    it("addr10 should sell land 1111, should FAIL", async () => {
      await expect(ovrMarketplace.connect(addr10).sell(111, 1000)).to.be
        .reverted;
    });

    it("addr1 should buy nft id 1111, should FAIL", async () => {
      await expect(ovrMarketplace.connect(addr1).buy(1111)).to.be.reverted;
    });

    it("addr10 should sell nft container id 2", async () => {
      await ovrMarketplace.connect(addr10).sellContainer(2, 2000);
    });

    it("addr1 should remove land 104 from container id 2, SHOULD FAIL 'CAUSE ON SALE", async () => {
      const lands = await ovrLandContainer.childsOfParent(2);
      console.debug(
        "Lands inside container 2 before remove land 104:\n",
        displayChildsOfParent(lands)
      );

      await expect(
        ovrLandContainer.connect(addr1).removeLandFromContainer(2, 104)
      ).to.be.reverted;

      const lands2 = await ovrLandContainer.childsOfParent(2);

      console.debug(
        "Lands inside container 2 after remove:",
        await displayChildsOfParent(lands2)
      );
    });

    it("addr1 should change sell price nft container id 2, SHOULD FAIL", async () => {
      await expect(ovrMarketplace.connect(addr1).updatePriceContainer(2, 4000))
        .to.be.reverted;
    });

    it("addr10 should change sell price nft container id 2", async () => {
      await ovrMarketplace.connect(addr10).updatePriceContainer(2, 4000);
    });

    it("addr1 should buy nft container id 2", async () => {
      console.debug(
        "\t\t\tbalance of address 10 before buy:",
        await ovrToken.balanceOf(addr10.address)
      );
      console.debug(
        "\t\t\tbalance of owner before buy:",
        await ovrToken.balanceOf(owner.address)
      );
      await ovrMarketplace.connect(addr1).buyContainer(2);
      console.debug(
        "\t\t\tbalance of address 10 after buy:",
        await ovrToken.balanceOf(addr10.address)
      );
      console.debug(
        "\t\t\tbalance of owner before buy:",
        await ovrToken.balanceOf(owner.address)
      );
      const ownerof = await ovrLandContainer.ownerOf(2);
      console.debug("\t\t\taddress 1 address:", addr1.address);
      console.debug("\t\t\towner of container 2:", ownerof);
    });

    it("addr1 should remove land 104 from container id 2", async () => {
      const lands = await ovrLandContainer.childsOfParent(2);
      console.debug(
        "Lands inside container 2 before remove land 104:",
        displayChildsOfParent(lands)
      );

      await ovrLandContainer.connect(addr1).removeLandFromContainer(2, 104);

      const lands2 = await ovrLandContainer.childsOfParent(2);

      console.debug(
        "Lands inside container 2 after remove:",
        displayChildsOfParent(lands2)
      );
    });

    it("addr1 should remove land 1040 from container id 2, SHOULD FAIL", async () => {
      await expect(
        ovrLandContainer.connect(addr1).removeLandFromContainer(2, 1040)
      ).to.be.reverted;
    });

    it("addr2 should remove land 105 from container id 2, SHOULD FAIL", async () => {
      await expect(
        ovrLandContainer.connect(addr2).removeLandFromContainer(2, 105)
      ).to.be.reverted;
    });

    it("addr1 should destroy container id 2", async () => {
      await ovrLandContainer.connect(addr1).deleteContainer(2);
      await expect(ovrLandContainer.connect(addr2).childsOfParent(2)).to.be
        .reverted;
      await expect(ovrLandContainer.connect(addr2).ownerOf(2)).to.be.reverted;
    });

    it("owner should mint 20 lands", async () => {
      await ovrLand
        .connect(addr10)
        .batchMintLands(
          [
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
            addr10.address,
          ],
          [
            1001, 1011, 1021, 1031, 1041, 1051, 1061, 1071, 1081, 1091, 1101,
            1111, 1121, 1131, 1141, 1151, 1161, 1171, 1181, 1191,
          ]
        );
    });

    it("addr10 should make container with 1001, 1011, 1021, 1031, 1041 land", async () => {
      await ovrLandContainer
        .connect(addr10)
        .createContainer([1001, 1011, 1021, 1031, 1041]);
    });

    it("owner should try to sell 1001, 1011, 1021, 1031, 1041 land separatly, FAIL", async () => {
      await expect(ovrMarketplace.connect(addr10).sell(1001, 10000)).to.be
        .reverted;
      await expect(ovrMarketplace.connect(addr10).sell(1011, 10000)).to.be
        .reverted;
      await expect(ovrMarketplace.connect(addr10).sell(1021, 10000)).to.be
        .reverted;
      await expect(ovrMarketplace.connect(addr10).sell(1031, 10000)).to.be
        .reverted;
      await expect(ovrMarketplace.connect(addr10).sell(1041, 10000)).to.be
        .reverted;
    });

    it("owner should delete container with 1001, 1011, 1021, 1031, 1041 land", async () => {
      await ovrLandContainer.connect(addr10).deleteContainer(3);
    });

    it("owner should  sell 1001, 1011, 1021, 1031, 1041 land separatly", async () => {
      await expect(ovrMarketplace.connect(addr10).sell(1001, 10000)).to.be.not
        .reverted;
      await expect(ovrMarketplace.connect(addr10).sell(1011, 10000)).to.be.not
        .reverted;
      await expect(ovrMarketplace.connect(addr10).sell(1021, 10000)).to.be.not
        .reverted;
      await expect(ovrMarketplace.connect(addr10).sell(1031, 10000)).to.be.not
        .reverted;
      await expect(ovrMarketplace.connect(addr10).sell(1041, 10000)).to.be.not
        .reverted;
    });

    it("owner should make an offer for land 1191", async () => {
      await ovrMarketplace.placeOffer(1191, 10);
    });

    it("addr10 should accept an offer for land 1191", async () => {
      await ovrMarketplace.connect(addr10).acceptOffer(1191);
    });
  });
});
