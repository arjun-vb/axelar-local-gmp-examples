// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';

contract Coordinator is AxelarExecutable { 

    enum State { PUBHLISHED, REDEEM, REFUND }

    uint constant participantCount = 2;
    string[] participantAddress;
    string[] participantChain;
    mapping(string => bool) public confirmation;
    mapping(string => bool) public funded;

    State currState = State.PUBHLISHED;
    bool verified = false;

    IAxelarGasService public immutable gasReceiver;

    constructor(address gateway_, address gasReceiver_) AxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
    }
    string public value;
    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        (value) = abi.decode(payload_, (string));
        if(stringEquals(value, "REGISTER")) {
            registerParticipants(sourceAddress_, sourceChain_);
        } else if(stringEquals(value, "CONFIRM")) {
            confirmVerification(sourceAddress_);
        }
    }
    function stringEquals(string memory first, string memory second) internal pure returns(bool) {
        if(keccak256(abi.encodePacked(first)) == keccak256(abi.encodePacked(second))) {
            return true;
        }
        return false;

    }

    function registerParticipants(string memory sourceAddress_, string memory sourceChain_) public {
        if(participantAddress.length < 2) {
            participantAddress.push(sourceAddress_);
            participantChain.push(sourceChain_);
        }
    }

    function confirmVerification(string memory sourceAddress_) public {
        for(uint i = 0; i < participantCount; i++) {
            if(stringEquals(participantAddress[i], sourceAddress_)) {
                confirmation[sourceAddress_] = true;
                break;
            }
        }
    }
    function fundConfirmation(string calldata sourceAddress_) public {
        for(uint i = 0; i < participantCount; i++) {
            if(stringEquals(participantAddress[i], sourceAddress_)) {
                funded[sourceAddress_] = true;
                break;
            }
        }
    }

    function verifyAll() public view returns(bool) {
        for(uint i = 0; i < participantCount; i++) {
            if(confirmation[participantAddress[i]] == false || funded[participantAddress[i]] == false) { //check exist condition
                return false;
            }
        }
        return true;
    }

    function redeem() public {
        if(currState == State.PUBHLISHED && verifyAll()) {
            currState = State.REDEEM;
            //send redeem to participants
        }
    }

    function refund() public {
        if(currState == State.PUBHLISHED) {
            currState = State.REFUND;
            //send refund to participants
        }
    }

}
