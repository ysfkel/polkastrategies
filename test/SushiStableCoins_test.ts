import { ethers, waffle } from "hardhat";
import { expect } from 'chai';
import { mainnet } from './network/address';
import { formatEther } from "ethers/lib/utils";
const ERC20 = require('../abi/ERC20.json');
const UniswapRouter = require('../abi/IUniswapRouter.json');
const UniswapFactory = require('../abi/IUniswapFactory.json');
const MasterChef = require('../abi/IMasterChef.json');

require('dotenv').config({ path: __dirname + '/../.env' })

var ms = new Date().getTime() + 86400000;
var tomorrow = new Date(ms);
const eth_amount = 10000000000000000000+'' 

const { DAI, USDC, USDT, WETH, SUSHI_SWAP_ROUTER } = process.env;

const poolId = 0

describe("SushiStableCoins Strategy Test", function() {    
    before('SushiStableCoins', async function (){
      const signers = await ethers.getSigners()
      this.deployer = signers[0] 
      this.deployerAddress = await this.deployer.getAddress()
      this.treasuryAddress = await signers[1].getAddress() 
      this.feeAddress = await signers[2].getAddress() 
      this.SushiStableCoin = await ethers.getContractFactory("SushiStableCoin"); 
      this.ReceiptToken = await ethers.getContractFactory("ReceiptToken"); 
    })
    beforeEach(async function () {
        this.sushiStableCoinStrategy = await this.SushiStableCoin.deploy()

        this.uniswapRouter = new ethers.Contract(mainnet.sushiswapRouter as string ,UniswapRouter, this.deployer)
 
        this.UniswapFactory = new ethers.Contract(mainnet.sushiswapFactory as string ,UniswapFactory, this.deployer)
        this.MasterChef = new ethers.Contract(mainnet.masterChef as string ,MasterChef, this.deployer)


        this.MasterChef = new ethers.Contract(mainnet.masterChef as string ,MasterChef, this.deployer)

        await this.sushiStableCoinStrategy.initialize(
          mainnet.masterChef,
          mainnet.sushiswapFactory,
          mainnet.sushiswapRouter,
          mainnet.wethAddress,
          mainnet.sushiAddress,
          this.treasuryAddress,
          this.feeAddress)

         await this.sushiStableCoinStrategy.grantOwnerRole(this.deployerAddress) 

        this.DAI = new ethers.Contract(mainnet.daiAddress as string ,ERC20, this.deployer)
        this.USDC = new ethers.Contract(USDC as string ,ERC20, this.deployer)
        this.USDT = new ethers.Contract(mainnet.usdtAddress as string ,ERC20, this.deployer)  
        // init receipts
        this.dai_receipt = await this.ReceiptToken.deploy()
        this.usdc_receipt = await this.ReceiptToken.deploy()
        this.usdt_receipt = await this.ReceiptToken.deploy()

        await this.dai_receipt.initialize(this.DAI.address, this.sushiStableCoinStrategy.address)
        await this.usdc_receipt.initialize(this.USDC.address, this.sushiStableCoinStrategy.address)
        await this.usdt_receipt.initialize(this.USDT.address, this.sushiStableCoinStrategy.address)
        
       // await this.sushiStableCoinStrategy.initAsset(DAI,this.dai_receipt.address, mainnet.ethDaiSlpAddress, )
        // await this.sushiStableCoinStrategy.initAsset(USDC,this.usdc_receipt.address)
        await this.sushiStableCoinStrategy.initAsset(USDT,this.usdt_receipt.address,  mainnet.usdtwethSLP, 0)
     }) 

     beforeEach(async function() {
        let swapPath = [WETH, mainnet.usdtAddress]
        await this.uniswapRouter.swapExactETHForTokens(0, swapPath, this.deployerAddress,tomorrow.getTime(), {value: '1000000000000000000'})      
     })
    
    it("should set arguments correctly", async function () { 
      expect(await this.sushiStableCoinStrategy.masterChef()).to.equal(mainnet.masterChef)
      expect(await this.sushiStableCoinStrategy.sushiswapFactory()).to.equal(mainnet.sushiswapFactory)
      expect(await this.sushiStableCoinStrategy.sushiswapRouter()).to.equal(mainnet.sushiswapRouter)
      expect(await this.sushiStableCoinStrategy.weth()).to.equal(mainnet.wethAddress)
      expect(await this.sushiStableCoinStrategy.sushi()).to.equal(mainnet.sushiAddress)
      expect(await this.sushiStableCoinStrategy.treasuryAddress()).to.equal(this.treasuryAddress)
      expect(await this.sushiStableCoinStrategy.feeAddress()).to.equal(this.feeAddress)
    })  

   it('should deposit ', async function(){
      let bal = await this.USDT.balanceOf(this.deployerAddress)
      let ethPerSushi = await this.uniswapRouter.getAmountsOut(bal, [mainnet.usdtAddress, mainnet.wethAddress]);
      await this.USDT.approve(this.sushiStableCoinStrategy.address, bal)
      await this.sushiStableCoinStrategy.deposit(mainnet.usdtAddress,bal, '400', ethPerSushi[1], tomorrow.getTime());
      const _asset = await this.sushiStableCoinStrategy.assets(mainnet.usdtAddress)
      const _user_deposit = await this.sushiStableCoinStrategy.userInfo(this.deployerAddress, mainnet.usdtAddress)
      expect(_user_deposit.totalInvested).gt(0)
      expect(_user_deposit.totalInvested).to.equal(bal)
      expect(_asset.totalAmount).to.equal(_user_deposit.totalInvested) 
   })

   it('should withdraw ', async function(){
    let bal = await this.USDT.balanceOf(this.deployerAddress)
    let ethPerSushi = await this.uniswapRouter.getAmountsOut(bal, [mainnet.usdtAddress, mainnet.wethAddress]);
    await this.USDT.approve(this.sushiStableCoinStrategy.address, bal)
    await this.sushiStableCoinStrategy.deposit(mainnet.usdtAddress,bal, '400', ethPerSushi[1], tomorrow.getTime());

    const _asset_deposit = await this.sushiStableCoinStrategy.assets(mainnet.usdtAddress)
    const _user_deposit_deposit = await this.sushiStableCoinStrategy.userInfo(this.deployerAddress, mainnet.usdtAddress)

    await this.sushiStableCoinStrategy.withdraw(mainnet.usdtAddress, _user_deposit_deposit.amount ,ethPerSushi[1], '400', tomorrow.getTime());
   
    const _asset_withdraw = await this.sushiStableCoinStrategy.assets(mainnet.usdtAddress)
    const  _user_deposit_withdraw = await this.sushiStableCoinStrategy.userInfo(this.deployerAddress, mainnet.usdtAddress)
    expect(_user_deposit_deposit.totalInvested).gt(_user_deposit_withdraw.totalInvested)
    expect(_asset_deposit.totalAmount).gt(_asset_withdraw.totalAmount)    
 })

});

 