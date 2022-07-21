import { ethers, waffle } from "hardhat";
import { expect } from 'chai';
import { mainnet } from './network/address';
const SushiStableCoinABI = require('../abi/SushiStableCoin.json')
 
describe("SushiStableCoinFactory Test", function() {
    before('SushiStableCoinFactory', async function (){
      const signers = await ethers.getSigners()
      this.deployer = signers[0] 
      this.user = signers[1] 
      this.deployerAddress = await this.deployer.getAddress()
      this.treasuryAddress = await signers[1].getAddress() 
      this.feeAddress = await signers[2].getAddress() 
      this.SushiStableCoinFactory = await ethers.getContractFactory("SushiStableCoinFactory"); 
      this.SushiStableCoin = await ethers.getContractFactory("SushiStableCoin"); 
      this.StrategyBeacon = await ethers.getContractFactory("SushiStableCoinStrategyBeacon"); 
      this.ReceiptToken = await ethers.getContractFactory("ReceiptToken"); 
      this.ReceiptTokenFactory = await ethers.getContractFactory('ReceiptTokenFactory')
    })

    beforeEach(async function () {
        // deploy receipt implementation 
        this.receiptTokenImplementation = await this.ReceiptToken.deploy()
        //deploy ReceiptTokenFactory
        this.receiptTokenFactory = await this.ReceiptTokenFactory.deploy(this.receiptTokenImplementation.address)
        // deploy harvest implementation
        this.strategyImplementation = await this.SushiStableCoin.deploy()
        // deploy beacon 
        this.strategyBeacon = await this.StrategyBeacon.deploy(this.strategyImplementation.address)
        //deploy SushiETHSLPFactory
        this.strategyFactory = await this.SushiStableCoinFactory.deploy(
          mainnet.masterChef,
          mainnet.sushiswapRouter,
          mainnet.sushiswapFactory,
          mainnet.sushiAddress, 
          mainnet.wethAddress,
          this.strategyBeacon.address)  

          await this.receiptTokenFactory.grantTokenCreatorRole(this.strategyFactory.address)
          await this.strategyFactory.grantRouterRole(this.deployerAddress)
    })
 

    it("should set arguments correctly", async function () {
       expect(await this.strategyFactory.masterChef()).to.equal( mainnet.masterChef)
       expect(await this.strategyFactory.sushiswapRouter()).to.equal( mainnet.sushiswapRouter)
       expect(await this.strategyFactory.sushiswapFactory()).to.equal( mainnet.sushiswapFactory)
       expect(await this.strategyFactory.sushi()).to.equal( mainnet.sushiAddress)
       expect(await this.strategyFactory.weth()).to.equal( mainnet.wethAddress) 
       expect(await this.strategyFactory.receiptTokenFactory()).to.equal(this.receiptTokenFactory.address)
       expect(await this.strategyFactory.strategyBeacon()).to.equal(this.strategyBeacon.address)
    })   

    context('Create SushiSLP Strategy Context', function() {
        beforeEach(async function() {
          await this.strategyFactory.createStrategy(this.treasuryAddress,this.feeAddress, this.deployerAddress)
          this.strateies = await this.strategyFactory.getStrategyUserStrategies();
          this.strategy = new ethers.Contract(this.strateies[0], SushiStableCoinABI, this.deployer)
        })

        it('should deploy SushiSLP strategy', async function() {
          expect((await this.strategyFactory.getStrategyUserStrategies()).length).to.equal(1)
        })
        it('should deploy SushiSLP strategy and set correct variables', async function() {
          expect(await this.strategy.masterChef()).to.equal( mainnet.masterChef)
          expect(await this.strategy.sushiswapRouter()).to.equal( mainnet.sushiswapRouter)
          expect(await this.strategy.sushiswapFactory()).to.equal( mainnet.sushiswapFactory)
          expect(await this.strategy.weth()).to.equal( mainnet.wethAddress)
          expect(await this.strategy.sushi()).to.equal( mainnet.sushiAddress)
          expect(await this.strategy.treasuryAddress()).to.equal(this.treasuryAddress)
          expect(await this.strategy.feeAddress()).to.equal(this.feeAddress)
        })
        it('should revert with Caller is not Owner', async function() {
            await expect(this.strategy.connect(this.user).setTreasury( this.deployerAddress)).to.be.revertedWith('revert Caller is not Owner')
        })
        it('should set new farm address', async function() {
          await this.strategy.setTreasury(this.feeAddress)
          expect(await this.strategy.treasuryAddress()).to.equal(this.feeAddress)
       }) 
    })

})