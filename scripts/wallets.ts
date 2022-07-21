

const dotenv = require('dotenv')
dotenv.config({ path: __dirname + '/../.env' });
dotenv.config({ path: __dirname + '/../.env.keys' });

import { ethers } from 'ethers';
import { BytesLike  } from "@ethersproject/bytes";
const { Wallet, providers: { JsonRpcProvider} } = ethers;
// RPC
export const mainnet_rpc = `${process.env.MAINNET}/${process.env.INFURA_API_KEY}`
export const kovan_rpc = `${process.env.KOVAN}/${process.env.INFURA_API_KEY}`
export const rinkeby_rpc = `${process.env.RINKEBY}/${process.env.INFURA_API_KEY}`
export const polygon_rpc = process.env.POLYGON
export const ganache_rpc = process.env.GANACHE
export const mumbai_rpc = process.env.POLYGON_TESTNET_MUMBAI 
// PROVIDERS
export const mainnet_provider = new JsonRpcProvider(mainnet_rpc)
export const kovan_provider = new JsonRpcProvider(kovan_rpc)
export const rinkeby_provider = new JsonRpcProvider(rinkeby_rpc)
export const polygon_provider = new JsonRpcProvider(polygon_rpc)
export const ganache_provider = new JsonRpcProvider(ganache_rpc)
export const mumbai_provider = new JsonRpcProvider(mumbai_rpc)
// WALLETS
export const mainnet_wallet = new Wallet(process.env.PRIVATE_KEY_1 as BytesLike, mainnet_provider)
export const kovan_wallet = new Wallet(process.env.PRIVATE_KEY_1 as BytesLike, kovan_provider)
export const rinkeby_wallet = new Wallet(process.env.PRIVATE_KEY_1 as BytesLike, rinkeby_provider)
export const polygon_wallet = new Wallet(process.env.PRIVATE_KEY_1 as BytesLike, polygon_provider)
export const ganache_wallet = new Wallet(process.env.PRIVATE_KEY_1 as BytesLike, ganache_provider)
export const mumbai_wallet = new Wallet(process.env.PRIVATE_KEY_1 as BytesLike, mumbai_provider)

