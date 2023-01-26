// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Coordinator { 

    enum State { PUBHLISHED, REDEEM, REFUND }
    uint constant participantCount = 2;
    string[] participantAddress;
    string[] participantChain;
    bool verified = false;
    mapping(string => bool) public confirmation;
    mapping(string => bool) public funded;
    State currState = State.PUBHLISHED;

    function registerParticipants(string calldata sourceAddress_, string calldata sourceChain_) public {
        if(participantAddress.length < 2) {
            participantAddress.push(sourceAddress_);
            participantChain.push(sourceChain_);
        }
    }

    function manualVerification(string calldata sourceAddress_) public {
        for(uint i = 0; i < participantCount; i++) {
            if(keccak256(abi.encodePacked(participantAddress[i])) == keccak256(abi.encodePacked(sourceAddress_))) {
                confirmation[sourceAddress_] = true;
                break;
            }
        }
    }
    function fundConfirmation(string calldata sourceAddress_) public {
        for(uint i = 0; i < participantCount; i++) {
            if(keccak256(abi.encodePacked(participantAddress[i])) == keccak256(abi.encodePacked(sourceAddress_))) {
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
