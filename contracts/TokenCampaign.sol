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

  TokenVault teamVault;

 
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
  address public teamVaultAddr = 0x0;
  
  // destination for reward tokens
  address public bountyVaultAddr;

  // destination for collected Ether
  address public trusteeVaultAddr;
  
  // destination for operational costs account
  address public opVaultAddr;
  

  // adress of our token
  address public tokenAddr;

  // decimals of our Token
  // constructor will pull the right value from the token
  uint8 public decimals;// = 3;
  
  // scale factor for rate and bonuses 
  // depends on decimals i.e. 
  // scale = (uint256(10) ** decimals);
  // we set it at deployment time
  uint256 public scale;
  
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
 
  /// @param  _trusteeAddress Team share 
  /// @param  _opAddress Team share 
  /// @param  _bountyAddress Team share 
 
  /// @param  _robotAddress Address of our processing backend
  function TokenCampaign(
    address _tokenAddress,
    address _trusteeAddress,
    address _opAddress,
    address _bountyAddress,
    address _robotAddress)
  {

    controller = msg.sender;
    
    /// set addresses     
    tokenAddr = _tokenAddress;
    //teamVaultAddr = _teamAddress;
    trusteeVaultAddr = _trusteeAddress; 
    opVaultAddr = _opAddress;
    bountyVaultAddr = _bountyAddress;
    robotAddr = _robotAddress;

    /// reference our token
    token = token_interface(tokenAddr);

   
   
    // adjust 'constants' for decimals used
    decimals = token.decimals();
    scale = (uint256(10) ** decimals);

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
    // adjust by factor 'scale' depending on token's decimals

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
  /// Functions that change contract state

  ///
  /// Setters
  ///


  /// this is only for emergency case
  function setRobotAddr(address _newRobotAddr) onlyController {
    require( _newRobotAddr != 0x0 );
    robotAddr = _newRobotAddr;
  }

  // we have to set team token address before campaign start
  function setTeamAddr(address _newTeamAddr) onlyController {
     require( campaignState > 2 && _newTeamAddr != 0x0 );
     teamVaultAddr = _newTeamAddr;
  }
 


  /// @notice  Puts campaign into active state  
  ///  only controller can do that
  ///  only possible 
  ///  WARNING: usual caveats apply to the Ethereum's interpretation of time
  function startSale() onlyController {
    // we only can start if team token Vault address is set
    require( campaignState > 2 && teamVaultAddr != 0x0);

    campaignState = 2;

    uint256 tNow = now;
    // assume timestamps will not cause overflow
    tCampaignStart = tNow;
    tBonusStageEnd += tNow;
    t_1st_StageEnd += tNow;
    t_2nd_StageEnd += tNow;
    t_3rd_StageEnd += tNow;
    tCampaignEnd += tNow;

   

   // CampaignOpen(now);
  }


  /// @notice Pause sale
  ///   just in case we have some troubles 
  ///   Note that time marks are not updated
  function pauseSale() onlyController {
    require( campaignState  == 2 );
    paused = true;
    CampaignPausd(now);
  }


  /// @notice Resume sale
  function resumeSale() onlyController {
    require( campaignState  == 2 );
    paused = false;
    CampaignResumed(now);
  }



  /// @notice Puts the camapign into closed state
  ///   only controller can do so
  ///   only possible from the active state
  ///   we can call this function if we want to stop sale before end time 
  ///   and be able to perform 'finalizeCampaign()' immediately
  function closeSale() onlyController {
    require( campaignState  == 2 );
    campaignState = 1;

  //  CampaignClosed(now);
  }   



  /// @notice Finalizes the campaign
  ///   Get funds out, generates team, bounty and reserve tokens
  function finalizeCampaign() {     
      
      /// only if sale was closed or 48 hours have passed since campaign end
      /// we leave this time to complete possibly pending orders
      /// from offchain contributions 
      require ( (campaignState == 1) ||
                ((campaignState != 0) && (now > tCampaignEnd + (48 hours))));
      
      campaignState = 0;

      // prevent further token generation
      token.finalize();     

      // forward funds to the trustee 
      // since we forward a fraction of the incomming ether on every contribution
      // 'amountRaised' IS NOT equal to the contract's balance
      // we use 'this.balance' instead
      trusteeVaultAddr.transfer(this.balance);
      
      // generate bounty tokens 
      uint256 bountyTokens = (tokensGenerated.mul(PRCT_BOUNTY)).div(100);
      require( do_grant_tokens(bountyVaultAddr, bountyTokens) ); 

      // generate team tokens
      uint256 teamTokens = (tokensGenerated.mul(PRCT_TEAM)).div(100);
      
      // time lock team tokens before transfer
      teamVault = TokenVault(teamVaultAddr);
      teamVault.setTimeLock( tCampaignEnd + 6 * (30 days));   
      // generate all the tokens
      require( do_grant_tokens(teamVaultAddr, teamTokens) );
      
      // notify the world
      Finalized();
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
  ///   checks campaign state, time window and minimal contribution
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
    TokenGranted(_toAddr, nTokens);
    TotalRaised(amountRaised);
  }


  /// @notice Gnenerate token "manually" without payment
  ///  We intend to use this to generate tokens from Bitcoin contributions without 
  ///  without Ether being sent to this contract
  ///  Note that this function can be triggered only by our BTC processing robot.  
  ///  A string reference is passed and logged for better book keeping
  ///  side effect: increases the generated tokens counter via do_grant_tokens
  /// @param _toAddr benificiary address
  /// @param _nTokens amount of tokens to be generated
  /// @param _ref payment reference e.g. Bitcoin address used for contribution 
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
  