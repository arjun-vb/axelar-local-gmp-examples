// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';

contract Coordinator is AxelarExecutable { 

    enum State { PUBHLISHED, REDEEM, REFUND }

    uint public immutable participantCount;
    string[] public participantAddress;
    string[] public participantChain;
    uint public registeredCount;
    mapping(string => bool) public confirmation;
    mapping(string => bool) public funded;

    State currState = State.PUBHLISHED;
    bool verified = false;
    string public message;

    IAxelarGasService public immutable gasReceiver;

    constructor(
        address gateway_, 
        address gasReceiver_,
        uint participantCount_
    ) AxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
        participantCount = participantCount_;
    }

    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        (message) = abi.decode(payload_, (string));
        if(stringEquals(message, "REGISTER")) {
            registerParticipant(sourceAddress_, sourceChain_);
        } else if(stringEquals(message, "CONFIRM")) {
            registerConfirmation(sourceAddress_);
        } else if(stringEquals(message, "FUNDED")) {
            registerFunds(sourceAddress_);
        }
    }

    function registerParticipant(string memory sourceAddress_, string memory sourceChain_) private {
        if(participantAddress.length < participantCount) {
            participantAddress.push(sourceAddress_);
            participantChain.push(sourceChain_);
            registeredCount++;
        }
    }

    function registerConfirmation(string memory sourceAddress_) private {
        for(uint i = 0; i < participantCount; i++) {
            if(stringEquals(participantAddress[i], sourceAddress_)) {
                confirmation[sourceAddress_] = true;
                break;
            }
        }
    }

    function registerFunds(string memory sourceAddress_) private {
        for(uint i = 0; i < participantCount; i++) {
            if(stringEquals(participantAddress[i], sourceAddress_)) {
                funded[sourceAddress_] = true;
                break;
            }
        }
    }

    function verifyAll() private view returns(bool) {
        for(uint i = 0; i < participantCount; i++) {
            if(confirmation[participantAddress[i]] == false || funded[participantAddress[i]] == false) { //check exist condition
                return false;
            }
        }
        return true;
    }

    function redeem() external {
        if(currState == State.PUBHLISHED && registeredCount == participantCount && verifyAll()) {
            currState = State.REDEEM;
            //send redeem to participants
        }
    }

    function refund() external {
        if(currState == State.PUBHLISHED) {
            currState = State.REFUND;
            //send refund to participants
        }
    }

    function stringEquals(string memory first, string memory second) internal pure returns(bool) {
        if(keccak256(abi.encodePacked(first)) == keccak256(abi.encodePacked(second))) {
            return true;
        }
        return false;
    }

}
