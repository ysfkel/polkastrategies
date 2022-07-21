import { ethers, waffle } from "hardhat";
import { expect } from 'chai';
import { mainnet } from './network/address';

describe("HarvestETH Strategy Test", function() {

    before('HarvestETH', async function (){
      const signers = await ethers.getSigners()
      this.deployer = signers[0] 
      this.deployerAddress = await this.deployer.getAddress()
      this.treasuryAddress = await signers[1].getAddress() 
      this.feeAddress = await signers[2].getAddress() 
      this.Harvest = await ethers.getContractFactory("Harvest"); 
      this.ReceiptToken = await ethers.getContractFactory("ReceiptToken"); 
    })

    beforeEach(async function () {
       this.harvest = await this.Harvest.deploy()
       this.receiptToken = await this.ReceiptToken.deploy()
       //
       await this.harvest.initialize(
          mainnet.harvestVault,
          mainnet.harvestPool,
          mainnet.sushiswapRouter,
          mainnet.farmAddress ,
          mainnet.farmAddress ,
          mainnet.sushiAddress,
          mainnet.wethAddress,
          this.treasuryAddress,
          this.feeAddress,
          this.receiptToken.address)

         this.harvest.grantOwnerRole(this.deployerAddress)
    }) 

    it("should set arguments correctly", async function () {
     expect(await this.harvest.harvestRewardVault()).to.equal(mainnet.harvestVault)
      expect(await this.harvest.harvestRewardPool()).to.equal(mainnet.harvestPool)
      expect(await this.harvest.sushiswapRouter()).to.equal(mainnet.sushiswapRouter)
      expect(await this.harvest.harvestfToken()).to.equal(mainnet.farmAddress)
      expect(await this.harvest.farmToken()).to.equal(mainnet.farmAddress)
      expect(await this.harvest.token()).to.equal(mainnet.sushiAddress)
      expect(await this.harvest.weth()).to.equal( mainnet.wethAddress)
      expect(await this.harvest.treasuryAddress()).to.equal(this.treasuryAddress)
      expect(await this.harvest.feeAddress()).to.equal(this.feeAddress)
      expect(await this.harvest.receiptToken()).to.equal(this.receiptToken.address)
   })  
     
});

 