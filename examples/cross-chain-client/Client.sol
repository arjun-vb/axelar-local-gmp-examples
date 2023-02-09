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

    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        string memory message;
        if(stringEquals(sourceAddress_, coordinatorAddress) &&
            stringEquals(sourceChain_, coordinatorChain)) {
            (message) = abi.decode(payload_, (string));
            if(stringEquals(message, "REDEEM")) {
                redeem();
            } else if(stringEquals(message, "REFUND")) {
                refund();
            } 
        }
    }

    function recieveFunds() external payable {
        total_funds += msg.value;
        if(address(this).balance >= fundsToTransfer) {
            funded = true;
            //sendCoordinator("FUNDED");
        }
    }

    function redeem() private {
        if(state == MyState.INITIAL) {
            payable(recieverAddress).transfer(address(this).balance);
            state = MyState.REDEEMED;
        }
    }

    function refund() private {
        if(state == MyState.INITIAL) {
            payable(owner).transfer(address(this).balance);
            state = MyState.REFUNDED;
        }
    }

    function stringEquals(string memory first, string memory second) internal pure returns(bool) {
        if(keccak256(abi.encodePacked(first)) == keccak256(abi.encodePacked(second))) {
            return true;
        }
        return false;
    }

}
