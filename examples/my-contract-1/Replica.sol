// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Replica { 

    enum CoordinatorState { PUBHLISHED, REDEEM, REFUND }
    enum MyState { INITIAL, REDEEMED, REFUNDED }
    address payable owner;
    uint public total_funds;
    bool public funded;
    uint constant public minFunds = 30;
    address constant public coordinatorAddress = 0xFBC3B76A206f03f1edbF411F280444cD3fD9c7C8;
    string constant public coordinatorChain = "ETHEREUM";
    address constant public recieverAddress = 0xFBC3B76A206f03f1edbF411F280444cD3fD9c7C8;
    MyState state = MyState.INITIAL;

    constructor() {
        owner = payable(msg.sender);
    }

    function register() public {
        funded = false;
        //register address with coordinator
    }

    function sendConfirmation() public pure returns(bool){
        return true;
        //send confirmation to coordinator
    }

    function recieveFunds() public payable {
        total_funds += msg.value;
        if(total_funds >= minFunds) {
            funded = true;
            //send fund confirmation
        }
    }

    function redeem() public {
        CoordinatorState coordinatorState = CoordinatorState.PUBHLISHED; //check coordinator status 
        if(coordinatorState == CoordinatorState.REDEEM && address(this).balance >= minFunds && state == MyState.INITIAL) {
            payable(recieverAddress).transfer(minFunds);
            //(bool sent, ) = payable(recieverAddress).call{value: minFunds}("");
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

}
