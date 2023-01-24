// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Replica { 

    address payable owner;
    uint total_funds;
    bool funded;
    const uint minFunds = 30;


    constructor() {
        owner = payable(msg.sender);
    }

    function recieveFunds() public payable {
        total_funds += msg.value;
        if(total_funds > minFunds) {
            funded = true;
        }
    }

    function redeem() {

    }

    function refund() {

    }

}
