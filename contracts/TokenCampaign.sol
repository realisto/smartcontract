// This is the code fot the smart contract 
// used for the Realisto ICO 
//
// @author: Pavel Metelitsyn
// September 2017


pragma solidity ^0.4.13;

import "./library.sol";
import "./RealistoToken.sol";
import "./LinearTokenVault.sol";

contract token_interface{
  uint8 public decimals;
  function generate_token_for(address _addr,uint _amount) returns (bool);
  function finalize();
}


// Controlled is implemented in MiniMeToken.sol
contract TokenCampaign is Controlled{
  using SafeMath for uint256;

  // this is our token
  token_interface public token;

 
  ///////////////////////////////////
  //
  // constants related to token sale

  // after slae ends, additional tokens will be generated
  // according to the following rules,
  // where 100% correspond to the number of sold tokens

  // percent of tokens to be generated for the team
  uint256 public constant PRCT_TEAM = 10;
  // percent of tokens to be generated for bounty
  uint256 public constant PRCT_BOUNTY = 3;
  // percent of tokens to be generated for reserve
  uint256 public constant PRCT_RESERVED = 0; // probably no reserved tokens

  // we keep ETH in the contract until the sale is finalized
  // however a small part of every contribution goes to opperational costs
  // percent of ETH going to operational account
  uint256 public constant PRCT_ETH_OP = 10;

  
  // CAUTION these 'constants' are adjusted at runtime 
  // by a scale factor = 10 ** decimals

  // how many tokens for one ETH
  uint256 public constant baseRate = 300;

  // minmal contribution, Wei
  uint256 public constant minContribution = (1 ether) / 100;

  // bonus structure, Wei
  uint256 public constant bonusMinContribution = (5 ether);
  // 
  uint256 public constant bonusAdd = 100; // + 30%
  uint256 public constant stage_1_add = 50;// + 15%
  uint256 public constant stage_2_add = 30;// + 10%
  uint256 public constant stage_3_add = 15;// + 5%
  
  ////////////////////////////////////////////////////////
  //
  // folowing addresses need to be set in the constructor
  // we also have setter functions which allow to change
  // an address if it is compromised or something happens

  // destination for team's share
  // this should point to an instance of TokenVault contract
  address public teamVaultAddr;
  
  // destination for token reserve
  address public reserveVaultAddr;
  
  // destination for reward tokens
  address public bountyVaultAddr;

  // destination for collected Ether
  address public trusteeVaultAddr;
  
  // destination for operational costs account
  address public opVaultAddr;


  TokenVault teamVault;
  TokenVault reserveVault;
  
  // adress of our token
  address public tokenAddr;
  uint8 public decimals = 3;
  uint256 public scale = (uint256(10) ** decimals);
  
  // address of our bitcoin payment processing robot
  // the robot is allowed to generate tokens without
  // sending ether
  // we do it to have more granular rights controll 
  address public robotAddr;
  
  
  /////////////////////////////////
  // Realted to Campaign


  // @check ensure that state transitions are 
  // only in one direction
  // 4 - passive, not accepting funds
  // 3 - active pre-sale ?
  // 2 - active main sale, accepting funds
  // 1 - closed, not accepting funds 
  // 0 - finalized, not accepting funds
  uint8 public campaignState = 4; 
  bool public paused = false;

  // keeps track of tokens generated so far
  // @check the implementation ensures amountGenerated <= availableTokens
  uint256 public tokensGenerated = 0;

  // total Ether raised (= Ether paid into the contract)
  uint256 public amountRaised = 0; 

  
  // this is the address where the funds 
  // will be transfered after the sale ends
  
  // time in seconds since epoch 
  // set to midnight of saturday January 1st, 4000

  uint256 public tCampaignStart = 64060588800;
  
  uint256 public tBonusStageEnd = 1 * 1 minutes;
  uint256 public t_1st_StageEnd = 120 * 1 minutes;
  uint256 public t_2nd_StageEnd = 180 * 1 minutes;
  uint256 public t_3rd_StageEnd = 240 * 1 minutes;
  uint256 public tCampaignEnd = 6 * 1 hours;

  //////////////////////////////////////////////
  //
  // Modifiers

  /// @notice The robot is allowed to generate tokens 
  ///   without sending ether
  ///  We do it to have more granular rights controll 
  modifier onlyRobot () { 
   require(msg.sender == robotAddr); 
   _;
  }

  //////////////////////////////////////////////
  //
  // Events
 
  event CampaignOpen(uint256);
  event CampaignClosed(uint256);
  event CampaignPausd(uint256);
  event CampaignResumed(uint256);
  event TokenGranted(address backer, uint amount, string ref);
  event TokenGranted(address backer, uint amount);
  event TotalRaised(uint raised);
  event Finalized();
 

  /// @notice Constructor
  /// @param _tokenAddress Our token's address
  /// @param  _teamAddress Team share 
  /// @param  _trusteeAddress Team share 
  /// @param  _opAddress Team share 
  /// @param  _bountyAddress Team share 
  /// @param  _reserveAdress Team share 
  /// @param  _robotAddress Address of our processing backend
  function TokenCampaign(
    address _tokenAddress,
    address _teamAddress,
    address _trusteeAddress,
    address _opAddress,
    address _bountyAddress,
    address _reserveAdress,
    address _robotAddress)
  {

   
    tokenAddr = _tokenAddress;

    teamVaultAddr = _teamAddress;
    trusteeVaultAddr = _trusteeAddress; 
    opVaultAddr = _opAddress;
    bountyVaultAddr = _bountyAddress;
    reserveVaultAddr = _reserveAdress;
    robotAddr = _robotAddress;

    /// reference our token

    controller = msg.sender;
    token = token_interface(tokenAddr);
 
    // adjust 'constants' for decimals used
    //decimals = token.decimals();
    //scale = (uint256(10) ** decimals);
 
   /* baseRate *= cale;
    minContribution *= scale;
    bonusMinContribution *= scale;
    bonusAdd *= scale;
    stage_1_add *= scale;
    stage_2_add *= scale;
    stage_3_add *= scale;*/

  }


  //////////////////////////////////////////////////
  ///
  /// Functions that do not change contract state


  /// @notice computes the current rate
  ///  according to time passed since the start
  /// @return amount of tokens per ETH
  function get_rate() returns (uint256){
    
    // obviously one gets 0 tokens
    // if campaign not yet started
    // or is already over
    if (now < tCampaignStart) return 0;
    if (now > tCampaignEnd) return 0;
    

    // compute rate per ETH based on time
    // assumes that time marks are increasing
    // from tBonusStageEnd through t_3rd_StageEnd

    if (now <= tBonusStageEnd)
      return scale * (baseRate + bonusAdd);

    if (now <= t_1st_StageEnd)
      return scale * (baseRate + stage_1_add);
    
    else if (now <= t_2nd_StageEnd)
      return scale * (baseRate + stage_2_add);
    
    else if (now <= t_3rd_StageEnd)
      return scale * (baseRate + stage_3_add);
    
    else 
      return baseRate * scale; 
  }


  /////////////////////////////////////////////
  ///
  /// functions that change contract state

  ///
  /// Setters
  ///

  function setRobotAddr(address _newRobotAddr) onlyController {
    
    robotAddr = _newRobotAddr;
  }

  
  function setTrusteeAddr(address _newTrusteeAddr) onlyController{
    require( (_newTrusteeAddr != 0x0) &&
             ( campaignState > 1) );
    trusteeVaultAddr = _newTrusteeAddr;
  }


  function setBountyAddr(address _newBountyAddr) onlyController{
     require( (_newBountyAddr != 0x0) &&
             ( campaignState > 1) );
    bountyVaultAddr = _newBountyAddr;
  }

  // we intend to use a time locked TokenVault contract as desination for team and reserve
  function setTeamAddr(address _newTeamAddr) onlyController{
     require( (_newTeamAddr != 0x0) &&
             ( campaignState > 1) );
    teamVaultAddr = _newTeamAddr;
  }

  function setReserveAddr(address _newReserveAddr) onlyController{
     require( (_newReserveAddr != 0x0) &&
             ( campaignState > 1) );
    reserveVaultAddr = _newReserveAddr;
  }
  


  /// @notice  Puts campaign into active state  
  ///  only controller can do that
  ///  only possible 
  ///  WARNING: usual caveats apply to the Ethereum's interpretation of time
  function startSale() onlyController {
    require( campaignState > 2 );

    campaignState = 2;

    tCampaignStart = now;
    tBonusStageEnd += now;
    t_1st_StageEnd += now;
    t_2nd_StageEnd += now;
    t_3rd_StageEnd += now;
    tCampaignEnd += now;
   // CampaignOpen(now);
  }


  /// @notice Puts the camapign into closed state
  ///   only controller can do so
  ///   only possible from the active state
  function closeSale() onlyController {
    require( campaignState  == 2 );
    campaignState = 1;

    teamVault = TokenVault(teamVaultAddr);
    reserveVault = TokenVault(reserveVaultAddr);
 

  //  CampaignClosed(now);
  }   


  /// @notice Pause sale
  ///   just in case we have some troubles 
  ///   Note that time marks are not updated
  function pauseSale() onlyController {
    paused = true;
    CampaignPausd(now);
  }


  /// @notice Resume sale
  function resumeSale() onlyController {
    paused = false;
    CampaignResumed(now);
  }


  /// @notice Finalizes the campaign
  ///   Get funds out, generates team, bounty and reserve tokens
  ///   Campaign must be closed explicitely before finalizeCampaign can be called
  ///   we need this to allow 
  function finalizeCampaign() {     
      
      //only if sale is closed
      require (campaignState == 1);

      campaignState = 0;

       // transfer funds to the trustee 
      // since we forward a fraction of the incomming ether on every contribution
      // 'amountRaised' IS NOT equal to the contract's balance
      // we use 'this.balance' instead
      trusteeVaultAddr.transfer(this.balance);
      
      // generates team tokens, bounty and reserve
      uint256 teamTokens = (PRCT_TEAM * tokensGenerated ) / 100;
      uint256 bountyTokens = (PRCT_BOUNTY * tokensGenerated ) / 100;
      uint256 reserveTokens = (PRCT_RESERVED * tokensGenerated ) / 100;

      // generate all the tokens
      require(do_grant_tokens(teamVaultAddr, teamTokens));
      require(do_grant_tokens(reserveVaultAddr, reserveTokens));
      require(do_grant_tokens(bountyVaultAddr, bountyTokens));

      teamVault.setTimeLock( now + 6 * (30 days));
      reserveVault.setTimeLock (now + 6 * (30 days));

      // prevent further token generation
      token.finalize();     
   }


  /// @notice triggers token generaton for the recipient
  ///  can be called only from the token sale contract itself
  ///  side effect: increases the generated tokens counter 
  ///  CAUTION: we do not check campaign state and parameters assuming that's calee's task
  function do_grant_tokens(address _to, uint256 _nTokens) internal returns (bool){
    
    require( token.generate_token_for(_to, _nTokens) );
    
    tokensGenerated = tokensGenerated.add(_nTokens);
    
    return true;
  }


  ///  @notice processes the contribution
  ///   checks campaign state, time frame and minimal contribution
  ///   throws if one of the conditions fails
  function process_contribution(address _toAddr) internal {
    
    require ((campaignState == 2)   // active main sale
         && (now <= tCampaignEnd)   // within time window
         && (paused == false));     // not on hold
      
  
    // during the bonus phase we require a minimal eth contribution 
    if ((now <= tBonusStageEnd) && 
             (msg.value <= bonusMinContribution )){
      revert();
    }      

  
    // otherwise we check that Eth sent is sufficient to generate at least one token
    // though our token has decimals we don't want nanocontributions
    require ( msg.value >= minContribution );

    // compute the rate
    uint256 rate = get_rate();
    
    // compute the amount of tokens to be generated
    uint256 nTokens = (rate.mul(msg.value)).div(1 ether);
    
    // compute the fraction of ETH going to op account
    uint256 opEth = (PRCT_ETH_OP.mul(msg.value)).div(100);


    // transfer to op account 
    opVaultAddr.transfer(opEth);
    
    // @todo check success (note we have no cap now so success is assumed)
    require( do_grant_tokens(_toAddr, nTokens) );

    amountRaised = amountRaised.add(msg.value);
    
    // notify the world
     // notify the world
    TokenGranted(_toAddr, nTokens);
    TotalRaised(amountRaised);
  }


  /// @notice Gnenerate token "manually" without payment
  ///  We intend to use this to generate tokens from Bitcoin contributions without 
  ///  without Ether being sent to this contract
  ///  Note that this function can be triggered only by our BTC processing robot.  
  ///  A string reference is passed and logged for better book keeping
  ///  side effect: increases the generated tokens counter via do_grant_tokens
  function grant_token_from_offchain(address _toAddr, uint _nTokens, string _ref) onlyRobot {
    require ( (campaignState == 2)
              ||(campaignState == 1));

    do_grant_tokens(_toAddr, _nTokens);
    TokenGranted(_toAddr, _nTokens, _ref);
  }


  /// @notice This function handles receiving Ether in favor of third party address
  ///   we can use this function for buying tokens on behalf
  /// @param _toAddr the address which will receive tokens
  function proxy_contribution(address _toAddr) payable {
    require ( _toAddr != 0x0 );
    /// prevent contracts from buying tokens
    /// we assume it is still usable for a while
    require( msg.sender == tx.origin );
    process_contribution(_toAddr);
  }


  /// @notice This function handles receiving Ether
  function () payable {
    /// prevent contracts from buying tokens
    /// we assume it is still usable for a while
    require( msg.sender == tx.origin );
    process_contribution(msg.sender);  
  }
}
  