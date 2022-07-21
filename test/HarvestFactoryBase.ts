import { ethers, waffle } from "hardhat";
import { expect } from 'chai';
import { mainnet } from './network/address'; 
 
describe("HarvestFactoryBase Test", function() {
    before('HarvestFactoryBase', async function (){
      const signers = await ethers.getSigners()
      this.deployer = signers[0] 
      this.user = signers[1] 
      this.deployerAddress = await this.deployer.getAddress()
      this.treasuryAddress = await signers[1].getAddress() 
      this.feeAddress = await signers[2].getAddress() 
      this.HarvestSCFactory = await ethers.getContractFactory("HarvestSCFactory"); 
      this.Harvest = await ethers.getContractFactory("HarvestSC"); 
      this.StrategyBeacon = await ethers.getContractFactory("HarvestSCStrategyBeacon"); 
      this.ReceiptToken = await ethers.getContractFactory("ReceiptToken"); 
      this.ReceiptTokenFactory = await ethers.getContractFactory('ReceiptTokenFactory')
    })

    beforeEach(async function () {
        // deploy receipt implementation 
        this.receiptTokenImplementation = await this.ReceiptToken.deploy()
        //deploy ReceiptTokenFactory
        this.receiptTokenFactory = await this.ReceiptTokenFactory.deploy(this.receiptTokenImplementation.address)
        // deploy harvest implementation
        this.HarvestSCImplementation = await this.Harvest.deploy()
        // deploy beacon 
        this.harvestStrategyBeacon = await this.StrategyBeacon.deploy(this.HarvestSCImplementation.address)
        //deploy HarvestSCFactory
        this.strategyFactory = await this.HarvestSCFactory.deploy(
          mainnet.harvestVault,
          mainnet.harvestPool,
          mainnet.sushiswapRouter,
          mainnet.farmAddress,
          mainnet.wethAddress,
          this.receiptTokenFactory.address,
          this.harvestStrategyBeacon.address)  

          await this.receiptTokenFactory.grantTokenCreatorRole(this.strategyFactory.address)
          await this.strategyFactory.grantRouterRole(this.deployerAddress)
    })

    it("should revert setHarvestRewardVault with 'Caller not admin' ", async function () {
      await expect(this.strategyFactory.connect(this.user).setHarvestRewardVault(mainnet.wethAddress)).to.be.revertedWith('Caller is not admin')
    }) 

    it("should revert setHarvestRewardVault with 'ADDRESS_0x0' ", async function () {
        await expect(this.strategyFactory.setHarvestRewardVault('0x0000000000000000000000000000000000000000')).to.be.revertedWith('ADDRESS_0x0')
    }) 

    it("should update harvestRewardVault ", async function () {
      await this.strategyFactory.setHarvestRewardVault(mainnet.wethAddress)
      expect(await this.strategyFactory.harvestRewardVault()).to.equal( mainnet.wethAddress)
    }) 

    it("should revert setHarvestRewardPool with 'Caller not admin' ", async function () {
        await expect(this.strategyFactory.connect(this.user).setHarvestRewardPool(mainnet.wbtcwethSLP)).to.be.revertedWith('Caller is not admin')
    }) 

    it("should revert setHarvestRewardPool with 'ADDRESS_0x0' ", async function () {
        await expect(this.strategyFactory.setHarvestRewardPool('0x0000000000000000000000000000000000000000')).to.be.revertedWith('ADDRESS_0x0')
    }) 
  
    it("should update  sushiswapFactory ", async function () {
        await this.strategyFactory.setHarvestRewardPool(mainnet.wbtcwethSLP)
        expect(await this.strategyFactory.harvestRewardPool()).to.equal(mainnet.wbtcwethSLP)
    }) 

    it("should revert setFarmToken with 'Caller not admin' ", async function () {
        await expect(this.strategyFactory.connect(this.user).setFarmToken(mainnet.wbtcwethSLP)).to.be.revertedWith('Caller is not admin')
    }) 
  
    it("should revert setFarmToken with 'ADDRESS_0x0' ", async function () {
        await expect(this.strategyFactory.setFarmToken('0x0000000000000000000000000000000000000000')).to.be.revertedWith('ADDRESS_0x0')
    }) 

    it("should update sushi ", async function () {
        await this.strategyFactory.setFarmToken(mainnet.wbtcwethSLP)
        expect(await this.strategyFactory.farmToken()).to.equal(mainnet.wbtcwethSLP)
    }) 
 

})