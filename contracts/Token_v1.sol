pragma solidity ^0.4.13;

import "./library.sol";

contract Token_v1 is ERC20_BasicToken, Controlled { 
  
  string public name = "RToken2";
  string public symbol = "RTB";
  uint16 decimals = 0;
  uint16 public version = 0;

  address public allowGenerate = 0x0;


  // can be used to lock all transactions
  //bool public locked;


  // the adress from which the dividend will be distributed
  address public dividend_paying_contract;

  // Events
  event Burn(address indexed from, uint256 value);

  // Constructor
  function Token_v1(uint16 _v) { // Constructor
    controller = msg.sender;
    allowGenerate = controller;
    version = _v; 
    totalSupply = 1000000;             // Update total supply
    //balances[msg.sender] = totalSupply;     // Give the creator all initial tokens
   
  }

  // can be set only once
  function allow_generate(address _addr) onlyController{
    //require(allowGenerate == 0x0);
    allowGenerate = _addr;
  }

  // @notice Generates tokens
  function generate_token_for(address _addr,uint _amount){
    // ensure that tokens can be generate
    require(msg.sender == allowGenerate);
    balances[_addr] += _amount;
    totalSupply -= _amount;

  }


  // @notice this is default function called when ETH is send to this contract
  // @notice it returns the funds to the sender, no changes are made 
  // @notice we use the campaign contract for selling tokens
  function () payable {
    revert();
  }

  /**/
  function claim() {
    // not implemented

  }



  // permanently disables generation of new tokens
  function finalize() onlyController{
    allowGenerate = 0x0;
  }

}