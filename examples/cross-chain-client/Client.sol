// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';

contract Client is AxelarExecutable { 
    IAxelarGasService public immutable gasReceiver;

    enum MyState { INITIAL, REDEEMED, REFUNDED }

    address payable owner;
    uint public total_funds = 0;
    bool public funded = false;
    MyState state = MyState.INITIAL;
    string public stateStr = "INITIAL";

    uint public immutable fundsToTransfer;
    string public coordinatorAddress;
    string public coordinatorChain;
    address public immutable recieverAddress;
    
    string public value;

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
        //require owner, limit messages
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

    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        if(stringEquals(sourceAddress_, coordinatorAddress) &&
            stringEquals(sourceChain_, coordinatorChain)) {
            (value) = abi.decode(payload_, (string));
            if(stringEquals(value, "REDEEM")) {
                redeem();
            } else if(stringEquals(value, "REFUND")) {
                refund();
            } 
        }
    }

    receive() external payable {
        total_funds += msg.value;
        if(total_funds >= fundsToTransfer) {
            funded = true;
            //sendCoordinator("FUNDED");
        }
    }

    function redeem() private {
        if(state == MyState.INITIAL) {
            payable(recieverAddress).transfer(address(this).balance);
            state = MyState.REDEEMED;
            stateStr = "REDEEMED";
        }
    }

    function refund() private {
        if(state == MyState.INITIAL) {
            payable(owner).transfer(address(this).balance);
            state = MyState.REFUNDED;
            stateStr = "REFUNDED";
        }
    }

    function stringEquals(string memory first, string memory second) internal pure returns(bool) {
        if(keccak256(abi.encodePacked(first)) == keccak256(abi.encodePacked(second))) {
            return true;
        }
        return false;
    }

    // function getCurrStateString(State state) internal pure returns(string memory) {
    //     string memory message;
    //     if(state == MyState.INITIAL) {
    //         message = "INITIAL";
    //     } else if(state == MyState.REDEEMED) {
    //         message = "REDEEMED";
    //     } else if(state == MyState.REFUNDED) {
    //         message = "REFUNDED";
    //     }
    //     return message;
    // }
}
