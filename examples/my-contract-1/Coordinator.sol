// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Coordinator { 

    enum State{ PUBHLISHED, REDEEM, REFUND }
    address const participants;
    bool verified = false;

    State currState = State.PUBHLISHED;


    constructor() {
    }

    function recieveFunds() public payable {
        total_funds += msg.value;
        if(total_funds > minFunds) {
            funded = true;
        }
    }

    function verifyContracts() {
        //check funded == true for all participants
        if(currState == State.PUBHLISHED && verified == true) {
            currState == State.REDEEM;
        }
    }

    function redeem() {
        verifyContracts();
        if(currState == State.REDEEM) {
            //send redeem to participants
        }
    }

    function refund() {
        if(currState == PUBHLISHED) {
            currState = State.REFUND;
            //send refund to participants
        }
    }

}
