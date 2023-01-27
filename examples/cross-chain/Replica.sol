// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

contract Replica is AxelarExecutable { 
    IAxelarGasService public immutable gasReceiver;

    enum CoordinatorState { PUBHLISHED, REDEEM, REFUND }
    enum MyState { INITIAL, REDEEMED, REFUNDED }

    address payable owner;
    uint public total_funds;
    bool public funded;
    uint constant public minFunds = 30;
    MyState state = MyState.INITIAL;

    address constant public coordinatorAddress = 0xFBC3B76A206f03f1edbF411F280444cD3fD9c7C8;
    string constant public coordinatorChain = "ETHEREUM";
    address constant public recieverAddress = 0xFBC3B76A206f03f1edbF411F280444cD3fD9c7C8;
    

    constructor(address gateway_, address gasReceiver_) AxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
        //owner = payable(msg.sender);
    }

    function register(
        string calldata destinationChain, 
        string calldata destinationAddress
    ) external payable {
        funded = false;
        bytes memory payload = abi.encode("REGISTER");
        if (msg.value > 0) {
            gasReceiver.payNativeGasForContractCall{ value: msg.value }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                msg.sender
            );
        }
        gateway.callContract(destinationChain, destinationAddress, payload);
        //register address with coordinator
    }

    function sendConfirmation(
        string calldata destinationChain, 
        string calldata destinationAddress
    ) external payable{
        bytes memory payload = abi.encode("CONFIRM");
        if (msg.value > 0) {
            gasReceiver.payNativeGasForContractCall{ value: msg.value }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                msg.sender
            );
        }
        gateway.callContract(destinationChain, destinationAddress, payload);
        
        //send confirmation to coordinator
    }

    function recieveFunds() public payable {
        total_funds += msg.value;
        if(total_funds >= minFunds) {
            funded = true;
            //send fund confirmation
        }
    }

    function redeem() public {
        CoordinatorState coordinatorState = CoordinatorState.PUBHLISHED; //check coordinator status 
        if(coordinatorState == CoordinatorState.REDEEM && address(this).balance >= minFunds && state == MyState.INITIAL) {
            payable(recieverAddress).transfer(minFunds);
            //(bool sent, ) = payable(recieverAddress).call{value: minFunds}("");
            //require(sent, "Failure!");
            state = MyState.REDEEMED;
        }
    }

    function refund() public {
        CoordinatorState coordinatorState = CoordinatorState.PUBHLISHED; //check coordinator status 
        if(coordinatorState == CoordinatorState.REFUND && state == MyState.INITIAL) {
            payable(owner).transfer(address(this).balance);
            //(bool sent, ) = owner.call{value: address(this).balance}("");
            //require(sent, "Failure!");
            state = MyState.REFUNDED;
        }
    }

}
