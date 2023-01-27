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
    uint public total_funds = 0;
    bool public funded = false;
    MyState state = MyState.INITIAL;

    uint public immutable fundsToTransfer;
    string public coordinatorAddress;
    string public coordinatorChain;
    string public recieverAddress;
    

    constructor(
        address gateway_, 
        address gasReceiver_, 
        string memory coordinatorAddress_,
        string memory coordinatorChain_,
        string memory recieverAddress_,
        uint fundsToTransfer_
    ) AxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
        coordinatorAddress = coordinatorAddress_;
        coordinatorChain = coordinatorChain_;
        recieverAddress = recieverAddress_;
        fundsToTransfer = fundsToTransfer_;
        owner = payable(msg.sender);
    }

    function register() external {
        sendCoordinator("REGISTER");
    }

    function sendConfirmation() external {
        sendCoordinator("CONFIRM");
    }

    function sendCoordinator ( string memory message_ ) public payable {
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

    function recieveFunds() public payable {
        total_funds += msg.value;
        if(total_funds >= fundsToTransfer) {
            funded = true;
            //send fund confirmation
        }
    }

    function redeem() public {
        CoordinatorState coordinatorState = CoordinatorState.PUBHLISHED; //check coordinator status 
        if(coordinatorState == CoordinatorState.REDEEM && address(this).balance >= fundsToTransfer && state == MyState.INITIAL) {
            //payable(recieverAddress).transfer(fundsToTransfer);
            //(bool sent, ) = payable(recieverAddress).call{value: fundsToTransfer}("");
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

    // function bytesToAddress (bytes memory b) internal returns (address) {
    //     uint result = 0;
    //     for (uint i = 0; i < b.length; i++) {
    //         uint c = uint(b[i]);
    //         if (c >= 48 && c <= 57) {
    //             result = result * 16 + (c - 48);
    //         }
    //         if(c >= 65 && c<= 90) {
    //             result = result * 16 + (c - 55);
    //         }
    //         if(c >= 97 && c<= 122) {
    //             result = result * 16 + (c - 87);
    //         }
    //     }
    //     return address(result);
    // }

}
