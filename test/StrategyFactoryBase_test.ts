import { ethers, waffle } from "hardhat";
import { expect } from 'chai';
import { mainnet } from './network/address';
 
describe("StrategyFactoryBase_test Test", function() {
    before('StrategyFactoryBase_test', async function (){
      const signers = await ethers.getSigners()
      this.deployer = signers[0] 
      this.user = signers[1] 
      this.deployerAddress = await this.deployer.getAddress()
      this.treasuryAddress = await signers[1].getAddress() 
      this.feeAddress = await signers[2].getAddress() 
      this.SushiSLPFactory = await ethers.getContractFactory("SushiSLPFactory"); 
      this.SushiSLP = await ethers.getContractFactory("SushiSLP"); 
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
        this.strategyImplementation = await this.SushiSLP.deploy()
        // deploy beacon 
        this.strategyBeacon = await this.StrategyBeacon.deploy(this.strategyImplementation.address)
        //deploy SushiETHSLPFactory 
        this.strategyFactory = await this.SushiSLPFactory.deploy(
          mainnet.masterChef,
          mainnet.sushiswapRouter,
          mainnet.sushiswapFactory,
          mainnet.sushiAddress, 
          mainnet.wethAddress,
          this.receiptTokenFactory.address,
          this.strategyBeacon.address)  
    
    })

    it("should revert setSushiswapRouter with 'Caller is not admin' ", async function () {
      await expect(this.strategyFactory.connect(this.user).setSushiswapRouter(mainnet.sushiAddress)).to.be.revertedWith('Caller is not admin')
    }) 

    it("should revert setSushiswapRouter with 'ADDRESS_0x0' ", async function () {
        await expect(this.strategyFactory.setSushiswapRouter('0x0000000000000000000000000000000000000000')).to.be.revertedWith('ADDRESS_0x0')
    }) 

    it("should update  masterChef ", async function () {
      await this.strategyFactory.setSushiswapRouter(mainnet.sushiAddress)
      expect(await this.strategyFactory.sushiswapRouter()).to.equal( mainnet.sushiAddress)
    }) 

    it("should revert setWETH with 'Caller is not admin' ", async function () {
        await expect(this.strategyFactory.connect(this.user).setWETH(mainnet.sushiAddress)).to.be.revertedWith('Caller is not admin')
    }) 

    it("should revert setWETH with 'ADDRESS_0x0' ", async function () {
        await expect(this.strategyFactory.setWETH('0x0000000000000000000000000000000000000000')).to.be.revertedWith('ADDRESS_0x0')
    }) 
  
    it("should update sushiswapFactory ", async function () {
        await this.strategyFactory.setWETH(mainnet.sushiAddress)
        expect(await this.strategyFactory.weth()).to.equal(mainnet.sushiAddress)
    }) 

    it("should revert setStrategyBeacon with 'Caller is not admin' ", async function () {
        await expect(this.strategyFactory.connect(this.user).setStrategyBeacon(mainnet.sushiAddress)).to.be.revertedWith('Caller is not admin')
    }) 
  
    it("should revert setStrategyBeacon with 'ADDRESS_0x0' ", async function () {
        await expect(this.strategyFactory.setStrategyBeacon('0x0000000000000000000000000000000000000000')).to.be.revertedWith('ADDRESS_0x0')
    }) 

    it("should update strategyBeacon ", async function () {
        await this.strategyFactory.setStrategyBeacon(mainnet.sushiAddress)
        expect(await this.strategyFactory.strategyBeacon()).to.equal(mainnet.sushiAddress)
    }) 

    it("should revert setReceiptTokenFactory with 'Caller is not admin' ", async function () {
        await expect(this.strategyFactory.connect(this.user).setReceiptTokenFactory(mainnet.sushiAddress)).to.be.revertedWith('Caller is not admin')
    }) 
  
    it("should revert setReceiptTokenFactory with 'ADDRESS_0x0' ", async function () {
        await expect(this.strategyFactory.setReceiptTokenFactory('0x0000000000000000000000000000000000000000')).to.be.revertedWith('ADDRESS_0x0')
    }) 

    it("should update receiptTokenFactory ", async function () {
        await this.strategyFactory.setReceiptTokenFactory(mainnet.sushiAddress)
        expect(await this.strategyFactory.receiptTokenFactory()).to.equal(mainnet.sushiAddress)
    }) 
})