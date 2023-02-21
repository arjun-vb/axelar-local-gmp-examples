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
    uint public registeredCount = 0;
    mapping(string => bool) public confirmation;
    mapping(string => bool) public funded;
    string public value;

    State currState = State.PUBHLISHED;
    string currStateStr = getCurrStateString(currState);

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
        //string memory message;
        (value) = abi.decode(payload_, (string));
        if(stringEquals(value, "REGISTER")) {
            registerParticipant(sourceAddress_, sourceChain_);
        } else if(stringEquals(value, "CONFIRM")) { //address and chain must be participants
            registerConfirmation(sourceAddress_, sourceChain_);
        } else if(stringEquals(value, "FUNDED")) {
            registerFunds(sourceAddress_, sourceChain_);
        } else if(stringEquals(value, "REDEEM")) {
            redeem();
        } else if(stringEquals(value, "REFUND")) {
            refund();
        }
    }

    function sendCurrentStateToClient(
        string calldata destinationChain,
        string calldata destinationAddress
    ) external payable {
        bytes memory payload = abi.encode(getCurrStateString(currState));
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
    }

    function registerParticipant(string memory sourceAddress_, string memory sourceChain_) private {
        if(registeredCount < participantCount) {
            participantAddress.push(sourceAddress_);
            participantChain.push(sourceChain_);
            registeredCount++;
            confirmation[string(string.concat(bytes(sourceAddress_), bytes(sourceChain_)))] == false;
            funded[string(string.concat(bytes(sourceAddress_), bytes(sourceChain_)))] == false;

        }
    }

    function registerConfirmation(string memory sourceAddress_, string memory sourceChain_) private {
        for(uint i = 0; i < participantCount; i++) {
            if(stringEquals(participantAddress[i], sourceAddress_) && 
                stringEquals(participantChain[i], sourceChain_)) {
                confirmation[string(string.concat(bytes(sourceAddress_), bytes(sourceChain_)))] = true;
                break;
            }
        }
    }

    function registerFunds(string memory sourceAddress_, string memory sourceChain_) private {
        for(uint i = 0; i < participantCount; i++) {
            if(stringEquals(participantAddress[i], sourceAddress_) && 
                stringEquals(participantChain[i], sourceChain_)) {
                funded[string(string.concat(bytes(sourceAddress_), bytes(sourceChain_)))] = true;
                break;
            }
        }
    }

    function verifyAll() private view returns(bool) {
        for(uint i = 0; i < participantCount; i++) {
            if(confirmation[string(string.concat(bytes(participantAddress[i]), bytes(participantChain[i])))] == false || 
                    funded[string(string.concat(bytes(participantAddress[i]), bytes(participantChain[i])))] == false) { //check exist condition
                return false;
            }
        }
        return true;
    }

    function redeem() private {
        if(currState == State.PUBHLISHED && registeredCount == participantCount && verifyAll()) {
            currState = State.REDEEM;
            currStateStr = getCurrStateString(currState);
        }
    }

    function refund() private {
        if(currState == State.PUBHLISHED) {
            currState = State.REFUND;
            currStateStr = getCurrStateString(currState);
        }
    }

    function stringEquals(string memory first, string memory second) internal pure returns(bool) {
        if(keccak256(abi.encodePacked(first)) == keccak256(abi.encodePacked(second))) {
            return true;
        }
        return false;
    }

    function getCurrStateString(State state) internal pure returns(string memory) {
        string memory message;
        if(state == State.PUBHLISHED) {
            message = "PUBHLISHED";
        } else if(state == State.REDEEM) {
            message = "REDEEM";
        } else if(state == State.REFUND) {
            message = "REFUND";
        }
        return message;
    }
}
