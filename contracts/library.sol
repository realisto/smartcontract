pragma solidity ^0.4.13;

// NOT USED AT THE MOMENT
// MUST BE IMPLEMENTED AS A LIBRARY
contract SafeArithmetics {

  function safe_add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function safe_sub(uint256 a, uint256 b) internal returns (uint256) {
    require(b <= a);
    return a - b;
  }

  
  function safe_mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function safe_div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}


//
// basic ERC20 
// @TO-DO: SafeArithmetics
//
contract ERC20_BasicToken is SafeArithmetics{


  // standard things
  uint256 public totalSupply;

  mapping (address => uint) balances;
  mapping (address => mapping (address => uint256)) allowed;

  // Events
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);


  // get balance 
  function balanceOf(address _addr) constant returns (uint256 balance) {
    return balances[_addr];
  }


  /* Internal transfer, only callable from within the contract */
  function _transfer(address _from, address _to, uint _value) internal {
      require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
      require (balances[_from] > _value);                // Check if the sender has enough
      require (balances[_to] + _value > balances[_to]); // Check for overflows
      balances[_from] -= _value;                         // Subtract from the sender
      balances[_to] += _value;                            // Add the same to the recipient
      Transfer(_from, _to, _value);
  }

    // transfer a token
  function transfer(address _to, uint256 _value) {
     _transfer(msg.sender, _to, _value);
    
    //balance[msg.sender] = safe_sub(balance[msg.sender], _value);
    //balance[_to] = safe_add(balance[_to], _value);
  }


  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

      require (_value < allowed[_from][msg.sender]);     // Check allowance
      allowed[_from][msg.sender] -= _value;
      _transfer(_from, _to, _value);
      return true;

    // var _allowance = allowed[_from][msg.sender];
    // if (_value > _allowance) rever;

    // balance[_to] = safe_add(balance[_to], _value);
    // balance[_from] = safe_sub(balance[_from],_value);
    // allowed[_from][msg.sender] = safe_sub(_allowance, _value);
    
    // trigger event
    // Transfer(_from, _to, _value);
  }


  function allowance(address _addr, address _spender) constant returns (uint256 remaining) {
    return allowed[_addr][_spender];
  }

  function approve(address _spender, uint256 _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

}



// others call it "owned" 
contract controlled { 
  address public controller;


  modifier onlyController {
      require(msg.sender == controller);
      _;
  }

  function transferControl(address newController) onlyController {
      controller = newController;
  }
}


contract Controlled {
  address public controller;

 	modifier onlyController() { if (msg.sender == controller) _; }

  function transferControl(address newController) onlyController {
    controller = newController;
  }
}

contract dividend_paying_contract { function claim() public returns (bool success);}

