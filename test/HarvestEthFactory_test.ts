import { ethers, waffle } from "hardhat";
import { expect } from 'chai';
import { mainnet } from './network/address';
const HarvestABI = require('../abi/Harvest.json')
 
describe("HarvestEthStrategyFactory Test", function() {
    before('HarvestEthStrategyFactory', async function (){
      const signers = await ethers.getSigners()
      this.deployer = signers[0] 
      this.user = signers[1] 
      this.deployerAddress = await this.deployer.getAddress()
      this.treasuryAddress = await signers[1].getAddress() 
      this.feeAddress = await signers[2].getAddress() 
      this.HarvestEthFactory = await ethers.getContractFactory("HarvestEthFactory"); 
      this.Harvest = await ethers.getContractFactory("Harvest"); 
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
        this.harvestEthImplementation = await this.Harvest.deploy()
        // deploy beacon 
        this.harvestStrategyBeacon = await this.StrategyBeacon.deploy(this.harvestEthImplementation.address)
        //deploy HarvestEthFactory
        this.strategyFactory = await this.HarvestEthFactory.deploy(
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

    it("should set arguments correctly", async function () {
       expect(await this.strategyFactory.harvestRewardVault()).to.equal( mainnet.harvestVault)
       expect(await this.strategyFactory.harvestRewardPool()).to.equal( mainnet.harvestPool)
       expect(await this.strategyFactory.sushiswapRouter()).to.equal( mainnet.sushiswapRouter)
       expect(await this.strategyFactory.farmToken()).to.equal( mainnet.farmAddress)
       expect(await this.strategyFactory.weth()).to.equal( mainnet.wethAddress)
       expect(await this.strategyFactory.receiptTokenFactory()).to.equal(this.receiptTokenFactory.address)
       expect(await this.strategyFactory.strategyBeacon()).to.equal(this.harvestStrategyBeacon.address)
    }) 

    context('Create Harvest Strategy Context', function() {
        beforeEach(async function() {
          await this.strategyFactory.createStrategy(mainnet.farmAddress,mainnet.sushiAddress,this.treasuryAddress,this.feeAddress,this.deployerAddress)
          this.strateies = await this.strategyFactory.getStrategyUserStrategies();
          this.strategy = new ethers.Contract(this.strateies[0], HarvestABI, this.deployer)
        })

        it('should deploy HarvestETH strategy', async function() {
            expect((await this.strategyFactory.getStrategyUserStrategies()).length).to.equal(1)
        })
        it('should deploy HarvestETH strategy and set correct variables', async function() {
            expect(await this.strategy.harvestRewardVault()).to.equal(mainnet.harvestVault)
            expect(await this.strategy.harvestRewardPool()).to.equal(mainnet.harvestPool)
            expect(await this.strategy.sushiswapRouter()).to.equal(mainnet.sushiswapRouter)
            expect(await this.strategy.harvestfToken()).to.equal(mainnet.farmAddress)
            expect(await this.strategy.farmToken()).to.equal(mainnet.farmAddress)
            expect(await this.strategy.token()).to.equal(mainnet.sushiAddress)
            expect(await this.strategy.weth()).to.equal( mainnet.wethAddress)
            expect(await this.strategy.treasuryAddress()).to.equal(this.treasuryAddress)
            expect(await this.strategy.feeAddress()).to.equal(this.feeAddress) 
        })
        it('should revert with Caller is not Owner', async function() {
            await expect(this.strategy.connect(this.user).setFarmToken(mainnet.farmAddress)).to.be.revertedWith('revert Caller is not Owner')
        })
        it('should set new farm address', async function() {
          const newFarmAddress = mainnet.sushiAddress
          await this.strategy.setFarmToken(newFarmAddress)
          expect(await this.strategy.farmToken()).to.equal(newFarmAddress)
      })
    })

})