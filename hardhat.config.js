require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");
require("hardhat-exposed");
require("solidity-coverage");
require("hardhat-contract-sizer");
require("@nomicfoundation/hardhat-toolbox-viem");
module.exports = {
    solidity: "0.8.20",
    exposed: {
        include: ["**/*"],
        imports: true,
        initializers: true,
        outDir: "contracts-exposed",
        exclude: ["vendor/**/*"],
    },
    contractSizer: {
        alphaSort: true,
        disambiguatePaths: false,
        runOnCompile: true,
        strict: true,
    },
};
