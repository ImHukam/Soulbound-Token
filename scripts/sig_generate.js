const hre = require("hardhat");
const { ethers, Wallet } = require('ethers');

const contractAddress = "0x61443969475EE1DB767f932D49F90C57B59AD58b"
const activeAddress = "0xdf39474cB1b8dC106b3636B1d854d4dE0Df446e4"; //receiver Address
const passiveAddress = "0xC980bBe81d7AE0CcbF72B6AbD59534dd8d176c77"; //signer/issuer Address
const passivePrivateKey = "59ae34146e6a5e43609ba9278b1ba4b8f81d615d06f036d7a064536bc71b6754";
const provider = new ethers.providers.JsonRpcProvider('https://rpc-mumbai.maticvigil.com');
const wallet = new ethers.Wallet(passivePrivateKey, provider);
const signer = wallet.connect(provider);

const types = {
  Agreement: [
    { name: "active", type: "address" },
    { name: "passive", type: "address" },
    { name: "tokenURI", type: "string" },
  ],
};


const domain = {
  name: "SoulBound",
  version: "1",
  chainId: 80001, // the chainId of foundry
  verifyingContract: contractAddress,
};

const agreement = {
  active: activeAddress,
  passive: passiveAddress,
  tokenURI: "https://ipfs.io/ipfs/QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/6588",
};

async function generateCompactSignature() {
  const signature = await signer._signTypedData(domain, types, agreement);
  const compactSign = ethers.utils.splitSignature(signature);
  console.log(compactSign)
}

generateCompactSignature()
