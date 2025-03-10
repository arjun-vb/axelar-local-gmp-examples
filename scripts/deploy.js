'use strict';

require('dotenv').config();
const {
    utils: { setJSON },
    testnetInfo,
} = require('@axelar-network/axelar-local-dev');
const { Wallet, getDefaultProvider, utils, ContractFactory } = require('ethers');
const { FormatTypes } = require('ethers/lib/utils');

async function deploy(env, chains, wallet, example, deployChainName, contractName) {

    if (example.preDeploy) {
			await example.preDeploy(chains, wallet);
    }

    const promises = [];

    for (const chain of chains) {
			if(chain.name == deployChainName) {
				const rpc = chain.rpc;
				const provider = getDefaultProvider(rpc);
				promises.push(example.deploy(chain, wallet.connect(provider), chains));
			}
    }

    await Promise.all(promises);

    if (example.postDeploy) {
			for (const chain of chains) {
				if(chain.name == deployChainName) {
					const rpc = chain.rpc;
					const provider = getDefaultProvider(rpc);
					promises.push(example.postDeploy(chain, wallet.connect(provider)));
				}
			}

			await Promise.all(promises);
    }

    for(const chain of chains) {
      if(chain.name == deployChainName) {
            for(const key of Object.keys(chain)) {

                if(chain[key].interface) {
                    const contract = chain[key];
                    const abi = contract.interface.format(FormatTypes.full);

                    const cont = {
                        name: contractName,
                        abi,
                        address: contract.address,
                    }
                    chain[key] = cont;
                    if(chain["contracts"]) {
                        chain["contracts"].push(cont);
                    } else {
                        chain["contracts"] = [];
                        chain["contracts"].push(cont);
                    }
                }
            }
        }
       // delete chain.wallet
    }

    setJSON(chains, `./info/${env}.json`);
}

module.exports = {
    deploy,
};

if (require.main === module) {
    const example = require(`../${process.argv[2]}/index.js`);

    const env = process.argv[3];
    if (env == null || (env !== 'testnet' && env !== 'local'))
        throw new Error('Need to specify testnet or local as an argument to this script.');
    let temp;

    if (env === 'local') {
        temp = require(`../info/local.json`);
    } else {
        try {
            temp = require(`../info/testnet.json`);
        } catch {
            temp = testnetInfo;
        }
    }

    const chains = temp;

    const privateKey = process.env.EVM_PRIVATE_KEY;
    const wallet = new Wallet(privateKey);

    deploy(env, chains, wallet, example, process.argv[4], process.argv[2]);
}
