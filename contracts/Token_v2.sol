pragma solidity ^0.4.13;

//import "./library.sol";
import "./MiniMeToken.sol";

contract Token_v2 is MiniMeToken { 

  //string public name = "RToken2";
  //string public symbol = "RTB";
  //uint16 decimals = 0;
  //uint16 public version = 0;
  
  // "last" block
  uint256 public checkpoint;

  address public allowGenerate = 0x0;


  // the adress from which the dividend will be distributed
  address public dividend_paying_contract;


  // Constructor
  function Token_v2(address _tokenFactory) // Constructor
    MiniMeToken(
      _tokenFactory,
      0x0,
      0,
      "Realisto Token",
      0,
      "RTB",
      true){
    
    controller = msg.sender;
    allowGenerate = controller;
  }


  // can be set only once
  function allow_generate(address _addr) onlyController{
    //require(allowGenerate == 0x0);
    allowGenerate = _addr;
  }


  // @notice this is default function called when ETH is send to this contract
  // @notice it returns the funds to the sender, no changes are made 
  // @notice we use the campaign contract for selling tokens
  function () payable {
    revert();
  }

  /**/
  function claim() {
    

  }

  
  // permanently disables generation of new tokens
  function finalize() {
    require (msg.sender == allowGenerate);
    allowGenerate = 0x0;
    checkpoint = block.number;

    //clone
  }

  // @notice| This function is to allow  triggered by our bitcoin robot
  function generate_token_for(address _addrTo, uint _amount){
    // ensure that tokens can be generated
    require(msg.sender == allowGenerate);
    
    //balances[_addr] += _amount;
   
    uint curTotalSupply = totalSupply();
    require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow    
    uint previousBalanceTo = balanceOf(_addrTo);
    require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
    updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
    updateValueAtNow(balances[_addrTo], previousBalanceTo + _amount);
    Transfer(0, _addrTo, _amount);
    //return true;
  }


  
}


