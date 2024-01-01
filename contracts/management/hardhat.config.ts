import "hardhat-deploy"
import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox-viem'
// import '@nomiclabs/hardhat-waffle'
import '@nomicfoundation/hardhat-toolbox'
import "@nomicfoundation/hardhat-ethers";
import "hardhat-deploy";
import "hardhat-deploy-ethers"; 
// import '@openzeppelin/hardhat-upgrades';
import { vars, task } from 'hardhat/config'
import type { NetworkUserConfig } from 'hardhat/types'

import './tasks/accounts'
import './tasks/deploy'

const { createAlchemyWeb3 } = require('@alch/alchemy-web3')

task(
  'nonce',
  'returns nonce and balance for specified address on multiple networks'
)
  .addParam('address')
  .setAction(async (address) => {
    const web3Sepolia = createAlchemyWeb3(
      (getChainConfig('sepolia') as any).url
    )
    const web3Polygon = createAlchemyWeb3(
      (getChainConfig('polygon-mainnet') as any).url
    )
    const web3Mainnet = createAlchemyWeb3(
      (getChainConfig('mainnet') as any).url
    )
    const web3Bsc = createAlchemyWeb3((getChainConfig('bsc') as any).url)
    const web3Avalanche = createAlchemyWeb3(
      (getChainConfig('avalanche') as any).url
    )

    const networkIDArr = ['Sepolia', 'Polygon ', 'Ethereum', 'BSC', 'Avalanche']
    const providerArr = [
      web3Sepolia,
      web3Polygon,
      web3Mainnet,
      web3Bsc,
      web3Avalanche,
    ]
    const resultArr : any[] = []

    for (let i = 0; i < providerArr.length; i++) {
      const nonce = await providerArr[i].eth.getTransactionCount(
        address.address,
        'latest'
      )
      const balance = await providerArr[i].eth.getBalance(address.address)
      resultArr.push([
        networkIDArr[i],
        nonce,
        parseFloat(providerArr[i].utils.fromWei(balance, 'ether')).toFixed(2) +
          'ETH',
      ])
    }
    resultArr.unshift(['  |NETWORK|   |NONCE|   |BALANCE|  '])
    console.log(resultArr)
  })

const mnemonic: string = vars.get('MNEMONIC')
const infuraApiKey: string = vars.get('INFURA_API_KEY')

const chainIds = {
  'arbitrum-mainnet': 42161,
  avalanche: 43114,
  bsc: 56,
  ganache: 1337,
  hardhat: 31337,
  mainnet: 1,
  'optimism-mainnet': 10,
  'polygon-mainnet': 137,
  'polygon-mumbai': 80001,
  sepolia: 11155111,
}

function getChainConfig(chain: keyof typeof chainIds): NetworkUserConfig {
  let jsonRpcUrl: string
  switch (chain) {
    case 'avalanche':
      jsonRpcUrl = 'https://api.avax.network/ext/bc/C/rpc'
      break
    case 'bsc':
      jsonRpcUrl = 'https://bsc-dataseed1.binance.org'
      break
    default:
      jsonRpcUrl = 'https://' + chain + '.infura.io/v3/' + infuraApiKey
  }
  return {
    accounts: {
      count: 10,
      mnemonic,
      path: "m/44'/60'/0'/0",
    },
    chainId: chainIds[chain],
    url: jsonRpcUrl,
  }
}

const config: HardhatUserConfig = {
  sourcify: {
    enabled: true,
  },
  defaultNetwork: 'hardhat',
  namedAccounts: {
    deployer: 0,
    mainDeployer:2,
  },
  etherscan: {
    apiKey: {
      avalanche: vars.get('SNOWTRACE_API_KEY', ''),
      bsc: vars.get('BSCSCAN_API_KEY', ''),
      mainnet: vars.get('ETHERSCAN_API_KEY', ''),
      polygon: vars.get('POLYGONSCAN_API_KEY', ''),
      sepolia: vars.get('ETHERSCAN_API_KEY', ''),
    },
  },
  gasReporter: {
    currency: 'USD',
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: './contracts',
  },
  networks: {
    hardhat: {
      accounts: {
        mnemonic,
      },
      chainId: chainIds.hardhat,
    },
    avalanche: getChainConfig('avalanche'),
    bsc: getChainConfig('bsc'),
    mainnet: getChainConfig('mainnet'),
    'polygon-mainnet': getChainConfig('polygon-mainnet'),
    sepolia: getChainConfig('sepolia'),
  },
  paths: {
    artifacts: './artifacts',
    cache: './cache',
    sources: './contracts',
    tests: './test',
  },
  solidity: {
    version: '0.8.20',
    settings: {
      metadata: {
        // Not including the metadata hash
        // https://github.com/paulrberg/hardhat-template/issues/31
        bytecodeHash: 'none',
      },
      // Disable the optimizer when debugging
      // https://hardhat.org/hardhat-network/#solidity-optimizer-support
      optimizer: {
        enabled: true,
        runs: 800,
      },
    },
  },
  typechain: {
    outDir: 'types',
    target: 'ethers-v6',
  }, 
}

export default config
