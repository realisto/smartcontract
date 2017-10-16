pragma solidity ^0.4.13;

import "./library.sol";
import "./MiniMeToken.sol";

contract RealistoToken is MiniMeToken { 

  // we use this variable to store the number of the finalization block
  uint256 public checkpointBlock;

  // address which is allowed to trigger tokens generation
  address public mayGenerateAddr;


  modifier mayGenerate() {
    require ( msg.sender == mayGenerateAddr );
    _;
  }

  // Constructor
  function RealistoToken(address _tokenFactory) 
    MiniMeToken(
      _tokenFactory,
      0x0,
      0,
      "name of our token",
      3, // decimals
      "symbol of our token",
      // SHOULD TRANSFERS BE ENABLED?
      true){
    
    controller = msg.sender;
    mayGenerateAddr = controller;
  }

  function setGenerateAddr(address _addr) onlyController{
    /// we set 'mayGenerateAddr' to 0x0 in 'finalize()'
    /// the following line enures that once the token is finalized
    /// nobody can ever generate new tokens 
    require(( mayGenerateAddr != 0x0) &&
            (_addr != 0x0));

    mayGenerateAddr = _addr;
  }


  /// @notice this is default function called when ETH is send to this contract
  ///   we use the campaign contract for selling tokens
  function () payable {
    revert();
  }

  
  /// @notice This function is copy-paste of the generateTokens of the original MiniMi contract
  ///   except it uses mayGenerate modifier (original uses onlyController)
  /// this is because we don't want the Sale campaign contract to be the controller
  function generate_token_for(address _addrTo, uint _amount) mayGenerate returns (bool) {
    
    //balances[_addr] += _amount;
   
    uint curTotalSupply = totalSupply();
    require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow    
    uint previousBalanceTo = balanceOf(_addrTo);
    require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
    updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
    updateValueAtNow(balances[_addrTo], previousBalanceTo + _amount);
    Transfer(0, _addrTo, _amount);
    return true;
  }

  // overwrites the original function
  function generateTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
    revert();
    generate_token_for(_owner, _amount);    
  }


  // permanently disables generation of new tokens
  function finalize() mayGenerate {
    mayGenerateAddr = 0x0;
    checkpointBlock = block.number;
  }  
}


