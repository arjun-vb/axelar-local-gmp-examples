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
const ExecutableSample = require('../../artifacts/examples/cross-chain-client/Client.sol/Client.json');

async function deploy(chain, wallet, chains) {
    console.log(`Deploying Client for ${chain.name}.`);
    const provider = getDefaultProvider(chain.rpc);
    chain.wallet = wallet.connect(provider);
    const destination = chains.find((chain) => chain.name === "Polygon");
    chain.contract = await deployContract(wallet, ExecutableSample, [chain.gateway, chain.gasReceiver, destination.contract.address, destination.name, "0x0411FC186c261bc75Cad577f1756871E3d50E899", 2]);
    console.log(`Deployed Client for ${chain.name} at ${chain.contract.address}.`);

}

async function test(chains, wallet, options) {
    const args = options.args || [];
    const getGasPrice = options.getGasPrice;
    const message = args[2];

    const source = chains.find((chain) => chain.name === args[0]);
    const destination = chains.find((chain) => chain.name === args[1]);
    //const message = args[2] || `Hello ${destination.name} from ${source.name}, it is ${new Date().toLocaleTimeString()}.`;

    async function logValue() {
        console.log(`value at ${destination.name} is "${await destination.contract.value()}"`);
        console.log(`COORDINATOR STATE:*************************`);
        console.log(`value at ${destination.name} is "${await destination.contract.value()}"`);
        //console.log(`src addr"${await destination.contract.addr()}"`);
        const count = await destination.contract.registeredCount();
        console.log(`registeredCount is ${count}`);
        //console.log(`current state is ${await destination.contract.currState()}`);
        
        if(count > 0) {
            console.log(`-------------------------------------`);
            const addr = await destination.contract.participantAddress(0);
            const cname = await destination.contract.participantChain(0);
            console.log(`participantChain 1 is ${cname}`);
            console.log(`participantAddress 1 is ${addr}`);
            console.log(`ConfirmationStatus 1 is ${await destination.contract.confirmation(addr+cname)}`);
            console.log(`fundStatus 1 is ${await destination.contract.funded(addr+cname)}`);
        }
        if(count > 1) {
            console.log(`-------------------------------------`);
            const addr = await destination.contract.participantAddress(1);
            const cname = await destination.contract.participantChain(1);
            console.log(`participantChain 2 is ${cname}`);
            console.log(`participantAddress 2 is ${addr}`);
            console.log(`ConfirmationStatus 2 is ${await destination.contract.confirmation(addr+cname)}`);
            console.log(`fundStatus 2 is ${await destination.contract.funded(addr+cname)}`);
        }

        console.log(`CLIENT STATE:*************************`);
        console.log(`client name is ${source.name}`);
        console.log(`current funds is ${await source.contract.total_funds()}`);
        //console.log(`current state is ${await source.contract.state()}`);
        console.log(`funded is ${await source.contract.funded()}`);
        console.log(`required funds is ${await source.contract.fundsToTransfer()}`);
        console.log(`coordinator address is ${await source.contract.coordinatorAddress()}`);
        console.log(`coordinator chain is ${await source.contract.coordinatorChain()}`);
    }
    if(message === "State") {
        await logValue();
    } else {
        console.log('--- Initially ---');
        await logValue();

        // Set the gasLimit to 3e5 (a safe overestimate) and get the gas price.
        const gasLimit = 3e5;
        const gasPrice = await getGasPrice(source, destination, AddressZero);

        const tx = await source.contract.sendCoordinator(message, {
            value: BigInt(Math.floor(gasLimit * gasPrice)),
        });
        await tx.wait();

        while ((await destination.contract.value()) !== message) {
            await sleep(1000);
        }

        console.log('--- After ---');
        await logValue();
    }
}

module.exports = {
    deploy,
    test,
};

// node scripts/deploy-1 examples/my-contract-1 local Ethereum

// node scripts/deploy-1 examples/my-contract-2 local Avalanche

// node scripts/test examples/my-contract-1 local "Ethereum" "Avalanche" 'Hello World 123'