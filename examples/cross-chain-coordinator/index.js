'use strict';

const {
    getDefaultProvider,
    Contract,
    constants: { AddressZero },
} = require('ethers');
const {
    utils: { deployContract },
} = require('@axelar-network/axelar-local-dev');

const { sleep } = require('../../utils');
const ExecutableSample = require('../../artifacts/examples/cross-chain-coordinator/Coordinator.sol/Coordinator.json');

async function deploy(chain, wallet) {
    console.log(`Deploying Coordinator on ${chain.name}.`);
    const provider = getDefaultProvider(chain.rpc);
    chain.wallet = wallet.connect(provider);
    const participantCount = 2;
    chain.contract = await deployContract(wallet, ExecutableSample, [chain.gateway, chain.gasReceiver, participantCount]);
    console.log(`Deployed Coordinator on ${chain.name} at ${chain.contract.address}.`);
}

async function test(chains, wallet, options) {
    const args = options.args || [];
    const getGasPrice = options.getGasPrice;

    const source = chains.find((chain) => chain.name === args[0]);
    const destination = chains.find((chain) => chain.name === args[1]);
    //const message = args[2] || `Hello ${destination.name} from ${source.name}, it is ${new Date().toLocaleTimeString()}.`;

    async function logValue() {
        console.log(`value at ${destination.name} is "${await destination.contract.value()}"`);
    }

    console.log('--- Initially ---');
    await logValue();

    // Set the gasLimit to 3e5 (a safe overestimate) and get the gas price.
    const gasLimit = 3e5;
    const gasPrice = await getGasPrice(source, destination, AddressZero);

    const tx = await source.contract.sendCoordinator("REGISTER", {
        value: BigInt(Math.floor(gasLimit * gasPrice)),
    });
    await tx.wait();

    while ((await destination.contract.value()) !== "REGISTER") {
        await sleep(1000);
    }

    console.log('--- After ---');
    await logValue();
}

module.exports = {
    deploy,
    test,
};

// node scripts/deploy-1 examples/my-contract-1 local Ethereum

// node scripts/deploy-1 examples/my-contract-2 local Avalanche

// node scripts/test examples/my-contract-1 local "Ethereum" "Avalanche" 'Hello World 123'

// node scripts/deploy examples/cross-chain-coordinator local Polygon 
// node scripts/deploy examples/cross-chain-client local Avalanche && node scripts/deploy examples/cross-chain-client local Ethereum