import { ethers, waffle } from "hardhat";
import { expect } from 'chai';
import { mainnet } from './network/address';
 
const zero_address='0x0000000000000000000000000000000000000000'
const poolId = 0;
describe("SushiSLP Strategy Test", function() {
    before('SushiSLP', async function (){
      const signers = await ethers.getSigners()
      this.deployer = signers[0] 
      this.deployerAddress = await this.deployer.getAddress()
      this.treasuryAddress = await signers[1].getAddress() 
      this.feeAddress = await signers[2].getAddress() 
      this.SushiSLP = await ethers.getContractFactory("SushiSLP"); 
      this.ReceiptToken = await ethers.getContractFactory("ReceiptToken"); 
    })
    beforeEach(async function () {
        this.sushiSLPStrategy = await this.SushiSLP.deploy()
        this.receiptToken = await this.ReceiptToken.deploy()

        await this.sushiSLPStrategy.initialize(
          mainnet.masterChef,
          mainnet.sushiswapFactory,
          mainnet.sushiswapRouter,
          mainnet.usdtAddress,
          mainnet.wethAddress,
          mainnet.sushiAddress,
          this.treasuryAddress,
          this.feeAddress,
          poolId,
          mainnet.usdtwethSLP,
          this.receiptToken.address)

          this.sushiSLPStrategy.grantOwnerRole(this.deployerAddress) 
     }) 
    it("should set arguments correctly", async function () {
      expect(await this.sushiSLPStrategy.masterChef()).to.equal( mainnet.masterChef)
      expect(await this.sushiSLPStrategy.sushiswapRouter()).to.equal( mainnet.sushiswapRouter)
      expect(await this.sushiSLPStrategy.sushiswapFactory()).to.equal( mainnet.sushiswapFactory)
      expect(await this.sushiSLPStrategy.token()).to.equal(mainnet.usdtAddress)
      expect(await this.sushiSLPStrategy.weth()).to.equal( mainnet.wethAddress)
      expect(await this.sushiSLPStrategy.sushi()).to.equal( mainnet.sushiAddress)
      expect(await this.sushiSLPStrategy.treasuryAddress()).to.equal(this.treasuryAddress)
      expect(await this.sushiSLPStrategy.feeAddress()).to.equal(this.feeAddress)
      expect(await this.sushiSLPStrategy.poolId()).to.equal(poolId)
      expect(await this.sushiSLPStrategy.slp()).to.equal(mainnet.usdtwethSLP)
      expect(await this.sushiSLPStrategy.receipt()).not.equal(zero_address)
   })  

});

 