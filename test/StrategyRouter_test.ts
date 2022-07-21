import { ethers, waffle } from "hardhat";
import { expect } from 'chai';
import { mainnet } from './network/address';
const HarvestABI = require('../abi/Harvest.json')
const HarvestSCABI = require('../abi/HarvestSC.json') 
const SushiSLPABI = require('../abi/SushiSLP.json')
const SushiStableCoinABI = require('../abi/SushiStableCoin.json')
const ERC20 = require('../abi/ERC20.json');
const UniswapFactory = require('../abi/IUniswapFactory.json');
const UniswapRouter = require('../abi/IUniswapRouter.json');
 
var ms = new Date().getTime() + 86400000;
var tomorrow = new Date(ms); 
const zero_address='0x0000000000000000000000000000000000000000'

describe("StrategyRouter Test", function() {
    before('StrategyRouter', async function (){
      const signers = await ethers.getSigners()
      this.deployer = signers[0] 
      this.user = signers[1] 
      this.deployerAddress = await this.deployer.getAddress()
      this.treasuryAddress = await signers[1].getAddress() 
      this.feeAddress = await signers[2].getAddress() 
      // router
      this.StrategyRouter = await ethers.getContractFactory("StrategyRouter"); 
      // factories
      this.HarvestEthFactory = await ethers.getContractFactory("HarvestEthFactory"); 
      this.HarvestSCFactory = await ethers.getContractFactory("HarvestSCFactory");  
      this.SushiSLPFactory = await ethers.getContractFactory("SushiSLPFactory"); 
      this.SushiStableCoinFactory = await ethers.getContractFactory("SushiStableCoinFactory"); 
      // strategies
      this.Harvest = await ethers.getContractFactory("Harvest"); 
      this.HarvestSC = await ethers.getContractFactory("HarvestSC"); 
      this.SushiSLP = await ethers.getContractFactory("SushiSLP");
      this.SushiStableCoin = await ethers.getContractFactory("SushiStableCoin"); 
      //
      this.StrategyBeacon = await ethers.getContractFactory("HarvestSCStrategyBeacon"); 
      this.ReceiptToken = await ethers.getContractFactory("ReceiptToken"); 
      this.ReceiptTokenFactory = await ethers.getContractFactory('ReceiptTokenFactory') 
    })
    beforeEach(async function () {
        // deploy receipt implementation 
        this.harvest_receiptTokenImplementation = await this.ReceiptToken.deploy()
        this.harvestsc_receiptTokenImplementation = await this.ReceiptToken.deploy()
        this.sushislp_receiptTokenImplementation = await this.ReceiptToken.deploy()
        this.sushisc_receiptTokenImplementation = await this.ReceiptToken.deploy()
        
        //deploy ReceiptTokenFactory
        this.receiptTokenFactory = await this.ReceiptTokenFactory.deploy(this.harvest_receiptTokenImplementation.address)
        /**
         * deploy strategy implementations
         */
        this.harvestEthImplementation = await this.Harvest.deploy()
        this.harvestSCthImplementation = await this.HarvestSC.deploy() 
        this.sushiSLPImplementation = await this.SushiSLP.deploy()
        this.sushiStableCoinImplementation = await this.SushiStableCoin.deploy()
        /**
         * deploy beacons
         */
        this.harvestStrategyBeacon = await this.StrategyBeacon.deploy(this.harvestEthImplementation.address)
        this.harvestSCStrategyBeacon = await this.StrategyBeacon.deploy(this.harvestSCthImplementation.address) 
        this.sushiSLPStrategyBeacon = await this.StrategyBeacon.deploy(this.sushiSLPImplementation.address)
        this.sushiStableCoinStrategyBeacon = await this.StrategyBeacon.deploy(this.sushiStableCoinImplementation.address) 

        this.USDT = new ethers.Contract(mainnet.usdtAddress as string ,ERC20, this.deployer)  
        this.USDTSlp = new ethers.Contract(mainnet.usdtwethSLP as string ,ERC20, this.deployer) 
        this.UniswapFactory = new ethers.Contract(mainnet.sushiswapFactory as string ,UniswapFactory, this.deployer)
        this.uniswapRouter = new ethers.Contract(mainnet.sushiswapRouter as string ,UniswapRouter, this.deployer)
    })

    beforeEach(async function() {
       await this.harvest_receiptTokenImplementation.initialize(mainnet.farmAddress, this.harvestEthImplementation.address) 
       await this.harvestEthImplementation.initialize(
            mainnet.harvestVault,
            mainnet.harvestPool,
            mainnet.sushiswapRouter,
            mainnet.farmAddress,
            mainnet.farmAddress,
            mainnet.farmAddress,
            mainnet.wethAddress,
            this.deployerAddress,
            this.deployerAddress,
            this.harvest_receiptTokenImplementation.address)

        await this.harvestsc_receiptTokenImplementation.initialize(mainnet.farmAddress, this.harvestSCthImplementation.address) 
        await this.harvestSCthImplementation.initialize(
            mainnet.harvestVault,
            mainnet.harvestPool,
            mainnet.sushiswapRouter,
            mainnet.farmAddress,
            mainnet.farmAddress,
            mainnet.farmAddress,
            mainnet.wethAddress,
            this.deployerAddress,
            this.deployerAddress,
            this.harvestsc_receiptTokenImplementation.address)

        await this.sushislp_receiptTokenImplementation.initialize(mainnet.usdtwethSLP, this.sushiSLPImplementation.address) 
        await this.sushiSLPImplementation.initialize(
            mainnet.masterChef,
            mainnet.sushiswapFactory,
            mainnet.sushiswapRouter,
            mainnet.usdtAddress,
            mainnet.wethAddress,
            mainnet.sushiAddress,
            this.deployerAddress,
            this.deployerAddress,
            2,
            mainnet.usdtwethSLP,
            this.receiptTokenFactory.address)

        await this.sushisc_receiptTokenImplementation.initialize(mainnet.usdtwethSLP, this.sushiStableCoinImplementation.address) 
        await this.sushiStableCoinImplementation.initialize(
                mainnet.masterChef,
                mainnet.sushiswapFactory,
                mainnet.sushiswapRouter,
                mainnet.wethAddress,
                mainnet.sushiAddress,
                this.deployerAddress,
                this.deployerAddress)  
    })
    beforeEach(async function () {   
      /**
       * deploy factories
       */

      // deploy HarvestEthFactory
      this.havestEthFactory = await this.HarvestEthFactory.deploy(
        mainnet.harvestVault,
        mainnet.harvestPool,
        mainnet.sushiswapRouter,
        mainnet.farmAddress,
        mainnet.wethAddress,
        this.receiptTokenFactory.address,
        this.harvestStrategyBeacon.address)  
      // deploy HarvestSCFactory 
      this.harvestSCFactory = await this.HarvestSCFactory.deploy(
          mainnet.harvestVault,
          mainnet.harvestPool,
          mainnet.sushiswapRouter,
          mainnet.farmAddress,
          mainnet.wethAddress,
          this.receiptTokenFactory.address,
          this.harvestSCStrategyBeacon.address)   
      this.sushiSLPFactory = await this.SushiSLPFactory.deploy(
          mainnet.masterChef,
          mainnet.sushiswapRouter,
          mainnet.sushiswapFactory,
          mainnet.sushiAddress,
          mainnet.wethAddress,
          this.receiptTokenFactory.address,
          this.sushiSLPStrategyBeacon.address) 

      this.sushiStableCoinFactory = await this.SushiStableCoinFactory.deploy(
            mainnet.masterChef,
            mainnet.sushiswapRouter,
            mainnet.sushiswapFactory,
            mainnet.sushiAddress, 
            mainnet.wethAddress,
            this.sushiStableCoinStrategyBeacon.address)  
   })

   beforeEach(async function () {   
      /**
       * deploy router
       */
      this.strategyRouter = await this.StrategyRouter.deploy(
          this.havestEthFactory.address,
          this.harvestSCFactory.address, 
          this.sushiSLPFactory.address,
          this.sushiStableCoinFactory.address
      )

      await this.receiptTokenFactory.grantTokenCreatorRole(this.havestEthFactory.address)
      await this.receiptTokenFactory.grantTokenCreatorRole(this.harvestSCFactory.address)
      await this.receiptTokenFactory.grantTokenCreatorRole(this.sushiSLPFactory.address) 
      await this.receiptTokenFactory.grantTokenCreatorRole(this.sushiStableCoinFactory.address) 

      await this.havestEthFactory.grantRouterRole(this.strategyRouter.address)
      await this.harvestSCFactory.grantRouterRole(this.strategyRouter.address)
      await this.sushiSLPFactory.grantRouterRole(this.strategyRouter.address)
      await this.sushiStableCoinFactory.grantRouterRole(this.strategyRouter.address)

   })

    it('correctly sets state variables', async function() {
        expect(await this.strategyRouter.harvestEthFactory()).to.equal(this.havestEthFactory.address)
        expect(await this.strategyRouter.harvestSCFactory()).to.equal(this.harvestSCFactory.address) 
        expect(await this.strategyRouter.sushiSLPFactory()).to.equal(this.sushiSLPFactory.address)
        expect(await this.strategyRouter.sushiStableCoinFactory()).to.equal(this.sushiStableCoinFactory.address)
    })
    context('Create Harvest Strategy Context', function() {
        beforeEach(async function() {
          await this.strategyRouter.createHarvestEthStrategy(mainnet.farmAddress,mainnet.sushiAddress,this.treasuryAddress, this.feeAddress)
          this.strateies = await this.havestEthFactory.getStrategyUserStrategies();
          this.strategy = new ethers.Contract(this.strateies[0], HarvestABI, this.deployer)
        })

        it('should deploy HarvestETH strategy', async function() {
            expect((await this.havestEthFactory.getStrategyUserStrategies()).length).to.equal(1)
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
    context('Create Harvestsc Strategy Context', function() {
        beforeEach(async function() {
          await this.strategyRouter.createHarvestSCStrategy(mainnet.farmAddress,mainnet.sushiAddress,this.treasuryAddress, this.feeAddress)
          this.strateies = await this.harvestSCFactory.getStrategyUserStrategies();
          this.strategy = new ethers.Contract(this.strateies[0], HarvestSCABI, this.deployer)
 
        })

        it('should deploy HarvestETH strategy', async function() {
            expect((await this.harvestSCFactory.getStrategyUserStrategies()).length).to.equal(1)
        })
        it('should deploy HarvestSC strategy and set correct variables', async function() {
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
    context('Create SushiSLP Strategy Context', function() {
       const poolId = 0
        beforeEach(async function() {
          await this.strategyRouter.createSushiSLPStrategy(mainnet.usdtAddress,this.treasuryAddress,this.feeAddress, poolId, mainnet.usdtwethSLP)
         this.strateies = await this.sushiSLPFactory.getStrategyUserStrategies();
         this.strategy = new ethers.Contract(this.strateies[0], SushiSLPABI, this.deployer)
        })

        beforeEach(async function() {
          let swapPath = [mainnet.wethAddress, mainnet.usdtAddress]
          const amount =  10000000000000000000
          const swapAmount = (amount/2 )+''
           await this.uniswapRouter.swapExactETHForTokens(0, swapPath, this.deployerAddress,tomorrow.getTime(), {value: swapAmount}) 
          //USDTSlp
          const bal =  await this.USDT.balanceOf(this.deployerAddress)
          await this.USDT.approve(this.uniswapRouter.address,bal )
          await this.uniswapRouter.addLiquidityETH(mainnet.usdtAddress,bal, 0,0,this.deployerAddress, tomorrow.getTime(), {value: swapAmount});
        })

        it('should deploy SushiSLP strategy', async function() {
          expect((await this.sushiSLPFactory.getStrategyUserStrategies()).length).to.equal(1)
        })
        it('should deploy SushiSLP strategy and set correct variables', async function() {
         expect(await this.strategy.masterChef()).to.equal( mainnet.masterChef)
          expect(await this.strategy.sushiswapRouter()).to.equal( mainnet.sushiswapRouter)
          expect(await this.strategy.sushiswapFactory()).to.equal( mainnet.sushiswapFactory)
          expect(await this.strategy.token()).to.equal(mainnet.usdtAddress)
          expect(await this.strategy.weth()).to.equal( mainnet.wethAddress)
          expect(await this.strategy.sushi()).to.equal( mainnet.sushiAddress)
          expect(await this.strategy.treasuryAddress()).to.equal(this.treasuryAddress)
          expect(await this.strategy.feeAddress()).to.equal(this.feeAddress)
          expect(await this.strategy.poolId()).to.equal(poolId)
          expect(await this.strategy.slp()).to.equal(mainnet.usdtwethSLP)
          expect(await this.strategy.receipt()).not.equal(zero_address)
        }) 

        it('should deposit ', async function(){
          let bal = await this.USDTSlp.balanceOf(this.deployerAddress) 
          await this.USDTSlp.approve(this.strategy.address, bal)
          await this.strategy.deposit(bal);
          const _asset = await this.strategy.asset()
          const _user_deposit = await this.strategy.userInfo(this.deployerAddress)
          expect(_user_deposit.totalInvested).gt(0)
          expect(_user_deposit.totalInvested).to.equal(bal)
          expect(_asset.totalAmount).to.equal(_user_deposit.totalInvested)  
       })

       it('should withdraw ', async function(){
        let bal = await this.USDTSlp.balanceOf(this.deployerAddress) 
        await this.USDTSlp.approve(this.strategy.address, bal)
        await this.strategy.deposit(bal); 
    
        const _asset_deposit = await this.strategy.asset()
        const _user_deposit_deposit = await this.strategy.userInfo(this.deployerAddress)
    
        await this.strategy.withdraw(_user_deposit_deposit.amount);
       
        const _asset_withdraw = await this.strategy.asset()
        const  _user_deposit_withdraw = await this.strategy.userInfo(this.deployerAddress)
        expect(_user_deposit_deposit.totalInvested).gt(_user_deposit_withdraw.totalInvested)
        expect(_asset_deposit.totalAmount).gt(_asset_withdraw.totalAmount)    
      })

      it('should revert with Caller is not Owner', async function() {
          await expect(this.strategy.connect(this.user).setTreasury( this.deployerAddress)).to.be.revertedWith('revert Caller is not Owner')
        })
        it('should set new farm address', async function() {
          await this.strategy.setTreasury(this.feeAddress)
          expect(await this.strategy.treasuryAddress()).to.equal(this.feeAddress)
       })
    })

    context('Create SushiStableCoinFactory Strategy Context', function() {
      const poolId = 0
       beforeEach(async function() {
         await this.strategyRouter.createSushiStableCoinStrategy(this.treasuryAddress,this.feeAddress)
        this.strateies = await this.sushiStableCoinFactory.getStrategyUserStrategies();
        this.strategy = new ethers.Contract(this.strateies[0], SushiStableCoinABI, this.deployer)
        this.receipt_token = await this.ReceiptToken.deploy()
        await this.receipt_token.initialize(mainnet.usdtwethSLP, this.strategy.address ) 
       })

       beforeEach(async function() {
        let swapPath = [mainnet.wethAddress, mainnet.usdtAddress]
         await this.uniswapRouter.swapExactETHForTokens(0, swapPath, this.deployerAddress,tomorrow.getTime(), {value: '1000000000000000000'})      
        })

      //  it('should deploy SushiStableCoin strategy', async function() {
      //    expect((await this.sushiStableCoinFactory.getStrategyUserStrategies()).length).to.equal(1)
      //  })
      //  it('should deploy SushiStableCoin strategy and set correct variables', async function() {
      //    expect(await this.strategy.masterChef()).to.equal( mainnet.masterChef)
      //    expect(await this.strategy.sushiswapRouter()).to.equal( mainnet.sushiswapRouter)
      //    expect(await this.strategy.sushiswapFactory()).to.equal( mainnet.sushiswapFactory)
      //    expect(await this.strategy.weth()).to.equal( mainnet.wethAddress)
      //    expect(await this.strategy.sushi()).to.equal( mainnet.sushiAddress)
      //    expect(await this.strategy.treasuryAddress()).to.equal(this.treasuryAddress)
      //    expect(await this.strategy.feeAddress()).to.equal(this.feeAddress)
      //  })
       it('should initialize an asset', async function() { 
 
        await this.strategy.initAsset(mainnet.usdtAddress, this.receipt_token.address, mainnet.usdtwethSLP, poolId)
        const asset = await this.strategy.assets(mainnet.usdtAddress)
        expect(asset.poolId).to.equal(poolId)
        expect(asset.slp).to.equal(mainnet.usdtwethSLP)
        expect(asset.receipt).not.equal(zero_address)
        expect(asset.token).to.equal(mainnet.usdtAddress)
       })

       it('should deposit ', async function(){
        await this.strategy.initAsset(mainnet.usdtAddress, this.receipt_token.address , mainnet.usdtwethSLP, poolId)
        let bal = await this.USDT.balanceOf(this.deployerAddress)
        let ethPerSushi = await this.uniswapRouter.getAmountsOut(bal, [mainnet.usdtAddress, mainnet.wethAddress]);
        await this.USDT.approve(this.strategy.address, bal)
        await this.strategy.deposit(mainnet.usdtAddress,bal, '400', ethPerSushi[1], tomorrow.getTime());
        const _asset = await this.strategy.assets(mainnet.usdtAddress)
        const _user_deposit = await this.strategy.userInfo(this.deployerAddress, mainnet.usdtAddress)
        expect(_user_deposit.totalInvested).gt(0)
        expect(_user_deposit.totalInvested).to.equal(bal)
        expect(_asset.totalAmount).to.equal(_user_deposit.totalInvested)  
       })

       it('should withdraw ', async function(){
        await this.strategy.initAsset(mainnet.usdtAddress, this.receipt_token.address , mainnet.usdtwethSLP, poolId)
        let bal = await this.USDT.balanceOf(this.deployerAddress)
        let ethPerSushi = await this.uniswapRouter.getAmountsOut(bal, [mainnet.usdtAddress, mainnet.wethAddress]);
        await this.USDT.approve(this.strategy.address, bal)
        await this.strategy.deposit(mainnet.usdtAddress,bal, '400', ethPerSushi[1], tomorrow.getTime());
      
        const _asset_deposit = await this.strategy.assets(mainnet.usdtAddress)
        const _user_deposit_deposit = await this.strategy.userInfo(this.deployerAddress, mainnet.usdtAddress)
        await this.strategy.withdraw(mainnet.usdtAddress, _user_deposit_deposit.amount ,ethPerSushi[1], '400', tomorrow.getTime());
        const _asset_withdraw = await this.strategy.assets(mainnet.usdtAddress)
        const  _user_deposit_withdraw = await this.strategy.userInfo(this.deployerAddress, mainnet.usdtAddress)
        expect(_user_deposit_deposit.totalInvested).gt(_user_deposit_withdraw.totalInvested)
        expect(_asset_deposit.totalAmount).gt(_asset_withdraw.totalAmount) 
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