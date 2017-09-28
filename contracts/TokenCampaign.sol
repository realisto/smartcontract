// This is the code fot the smart contract 
// used for ICO 
//
// @author: Pavel Metelitsyn
// September 2017


pragma solidity ^0.4.13;

import "./library.sol";
import "./Token_v1.sol";

contract token_interface{
  function generate_token_for(address _addr,uint _amount);
  function finalize();
}

contract TokenCampaign is Controlled{

    // this is our token
    token_interface public token;

	  // this is the address where the funds 
	  // will be transfered after the sale ends
    address public trusteeVault;
    address public tokenController;
    address public tokenAddress;
   
    /////////////////////////////
    // Static Addresses
    //
    address public TEAM_ADDR = 0xE2fa819dFd9a2ddD7354E5E122b0B493B97B894A;
    address public TRUSTEE_VAULT = 0x0;


    // the max totalSupply of the Token
    uint256 public TOKEN_CAP = 1000;
    //  10% are reserved for the team
    uint256 public PRCT_TEAM = 10;
    

    // @check computer in the Constructor
    uint256 public availableTokens;

    // keeps track of tokens generated so far
    // @check the implementation ensures amountGenerated <= availableTokens
    uint256 public tokensGenerated = 0;

    // total Ether raised 
    uint256 public amountRaised = 0; 
  

    ////////////////////////////////
    // Related to Sale Coditions
    //
    // how many tokens for one eth
    uint256 public base_rate = 3; 
    //
    // not sure if need this
    uint256 public min_contribution;
    //
    // bonuses for big buyers     
    uint256 public bonus_threshold_1 = 5 ether;
    uint256 public bonus_threshold_2 = 10 ether;
    
  
    
    
    /////////////////////////////////
    // Realted to Campaign
    //

    // @check ensure that state transitions are 
    // only in one direction
    // 4 - passive, not accepting funds
    // 3 - active pre-sale ?
    // 2 - active main sale, accepting funds
    // 1 - closed, not accepting funds 
    // 0 - finalized, not accepting funds
    uint8 public campaignState = 4; 

    // seconds since epoch 
    // set to midnight of saturday January 1st, 4000
    uint256 public tStart = 64060588800;
    uint256 public tEnd = 64060588800; 
    
    // @todo change duration
    uint256 public tDuration;


    event TokenGranted(address backer, uint amount);
    event TotalRaised(uint raised);
    
    modifier afterCampaignEnded() { 
      if (now > tEnd) _;
    }
    
    function startSale() onlyController {
      require(campaignState > 2);

        tStart = now;
        tEnd = tStart + tDuration;
        campaignState = 2;
    }

    function closeSale() onlyController {
      require(campaignState  == 2);
      campaignState = 1;
    }   

    // @notice Constructor
    // @param _rtoken_address
    // @param _duration Duration of the campaign in seconds
    function TokenCampaign(
      address _tokenAddress,
      address _trusteeVault,
      address _tokenController,
      uint256 _duration)
    {
    	
      trusteeVault = _trusteeVault; 
     // trustee_vault = 0x6A46790Ce615882eDf46c175Cb9909dFD8d7Eb85; 
    	
      controller = msg.sender;

      tokenController = _tokenController;
     // tokenController = 0x3beb6fE405c492Bf7bD9603E21af25A072504303;

      tokenAddress = _tokenAddress;
     // tokenAddress = 0x5B45a87a3bD1666D4fafB6493844AF72aB568cCa;
      token = token_interface(tokenAddress);

      availableTokens =  (100 - PRCT_TEAM) * TOKEN_CAP / 100;
      tDuration = _duration;

    }


    // this should be made internal
    // @todo where keep book of BTC funds received?
    function do_grant_tokens(address _to, uint256 _nTokens) internal{
      // more tokens requested than we can provide
      if (_nTokens > availableTokens) 
        revert();

      amountRaised += msg.value;
      availableTokens -= _nTokens;
      tokensGenerated += _nTokens;

      // @todo check success 
      token.generate_token_for(_to, _nTokens);
      

      TokenGranted(msg.sender, _nTokens);
      TotalRaised(amountRaised);
    }

    /// @notice This function handles receiving Ether
    /// @return True if accepted, false otherwise
    function () payable {
        require (campaignState == 2); // active main sale
        
        uint256 rate = get_rate();
        uint256 nTokens = rate * (msg.value / 1 ether);
        // @todo check success

        // add bonus based on contribution
        if (msg.value >= bonus_threshold_2)
          nTokens += 5;
        else if (msg.value >= bonus_threshold_1)
          nTokens += 3;
       

        do_grant_tokens(msg.sender, nTokens);
    
    }

    // @notice gnenerate token "manually"
    // @notice this function can be bo 
    function grant_token_from_offchain_transaction(
      address _to,
      uint _nTokens)
    
    {
      require (campaignState == 2);
      do_grant_tokens(_to, _nTokens);
    }

    // @todo How we compute rate per bitcoin?
    // @todo presale?
    // @notice computes the current rate 
    function get_rate() returns (uint256){
      
      if (now < tStart) 
        return 0;
      

      // compute bonus based on time

    	if (now < tStart + 1 minutes)
    		return base_rate + 2;
    	else if (now < tStart + 2 minutes )
    		return base_rate + 1;
      else 
        return base_rate;
      
    }




    // get funds out, get team share
    // @todo add afterCampaignEnde
    function finalizeCampaign() onlyController { 		
        require (campaignState == 1 || campaignState == 2);

        campaignState = 0;
        // generates team tokens and disable token generation
        uint256 teamShareTokens = (PRCT_TEAM * tokensGenerated ) / 100;
        token.generate_token_for(TEAM_ADDR, teamShareTokens);
        
       
        availableTokens = 0;
        // @todo do we need disabling?
        token.finalize();
        
        // transfer funds to the trustee 
        // @todo check if something is left in the contract
        trusteeVault.transfer(amountRaised);
     }
}
  