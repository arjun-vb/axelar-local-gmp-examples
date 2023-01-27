// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';

contract Replica is AxelarExecutable { 
    IAxelarGasService public immutable gasReceiver;

    enum CoordinatorState { PUBHLISHED, REDEEM, REFUND }
    enum MyState { INITIAL, REDEEMED, REFUNDED }

    address payable owner;
    uint public total_funds = 0;
    bool public funded = false;
    MyState state = MyState.INITIAL;

    uint public immutable fundsToTransfer;
    string public coordinatorAddress;
    string public coordinatorChain;
    address public immutable recieverAddress;
    

    constructor(
        address gateway_, 
        address gasReceiver_, 
        string memory coordinatorAddress_,
        string memory coordinatorChain_,
        address recieverAddress_,
        uint fundsToTransfer_
    ) AxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
        coordinatorAddress = coordinatorAddress_;
        coordinatorChain = coordinatorChain_;
        recieverAddress = recieverAddress_;
        fundsToTransfer = fundsToTransfer_;
        owner = payable(msg.sender);
    }

    function sendCoordinator ( string memory message_ ) public payable {
        //require owner
        bytes memory payload = abi.encode(message_);
        if (msg.value > 0) {
            gasReceiver.payNativeGasForContractCall{ value: msg.value }(
                address(this),
                coordinatorChain,
                coordinatorAddress,
                payload,
                msg.sender
            );
        }
        gateway.callContract(coordinatorChain, coordinatorAddress, payload);
    }

    function recieveFunds() external payable {
        total_funds += msg.value;
        if(address(this).balance >= fundsToTransfer) {
            funded = true;
            sendCoordinator("FUNDED");
        }
    }

    function redeem() external {
        CoordinatorState coordinatorState = CoordinatorState.PUBHLISHED; //check coordinator status 
        if(coordinatorState == CoordinatorState.REDEEM && state == MyState.INITIAL) {
            payable(recieverAddress).transfer(address(this).balance);
            state = MyState.REDEEMED;
        }
    }

    function refund() external {
        CoordinatorState coordinatorState = CoordinatorState.PUBHLISHED; //check coordinator status 
        if(coordinatorState == CoordinatorState.REFUND && state == MyState.INITIAL) {
            payable(owner).transfer(address(this).balance);
            state = MyState.REFUNDED;
        }
    }

}
