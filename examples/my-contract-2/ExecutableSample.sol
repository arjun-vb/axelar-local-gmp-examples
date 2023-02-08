// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';

contract ExecutableSample is AxelarExecutable {
    string public value;
    //string public value2;
    IAxelarGasService public immutable gasReceiver;


    uint public immutable participantCount;
    string[] public participantAddress;
    string[] public participantChain;
    uint public registeredCount = 0;
    mapping(string => bool) public confirmation;
    mapping(string => bool) public funded;
    string public addr;


    constructor(
        address gateway_, 
        address gasReceiver_,
        uint participantCount_
    ) AxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
        participantCount = participantCount_;
    }
    
    // Handles calls created by setAndSend. Updates this contract's value
    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        (value) = abi.decode(payload_, (string));
        addr = sourceAddress_;
        if(stringEquals(value, "REGISTER")) {
            registerParticipant(sourceAddress_, sourceChain_);
        } else if(stringEquals(value, "CONFIRM")) { //address and chain must be participants
            registerConfirmation(sourceAddress_, sourceChain_);
        } 
    }

    function registerParticipant(string memory sourceAddress_, string memory sourceChain_) private {
        if(registeredCount < participantCount) {
            participantAddress.push(sourceAddress_);
            participantChain.push(sourceChain_);
            registeredCount++;
        }
    }
    
    function registerConfirmation(string memory sourceAddress_, string memory sourceChain_) private {
        for(uint i = 0; i < participantCount; i++) {
            if(stringEquals(participantAddress[i], sourceAddress_) && 
                stringEquals(participantChain[i], sourceChain_)) {
                confirmation[sourceAddress_] = true;
                break;
            }
        }
    }

    function stringEquals(string memory first, string memory second) internal returns(bool) {
        if(keccak256(abi.encodePacked(first)) == keccak256(abi.encodePacked(second))) {
            return true;
        }
        return false;
    }
}
