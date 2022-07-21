import Wallet from 'ethereumjs-wallet';
import { toBuffer }  from 'ethereumjs-util';

export const getAddressKey =( privateKey: string):string => {
    const privateKeyBuffer = toBuffer(privateKey)
    const wallet = Wallet.fromPrivateKey(privateKeyBuffer)
    return wallet.getAddressString()
}

export const getPublicKey =( privateKey: string):string => {
    const privateKeyBuffer = toBuffer(privateKey)
    const wallet = Wallet.fromPrivateKey(privateKeyBuffer)
    return wallet.getPublicKeyString()
}

