/// This is the code fot the smart contract 
/// used for the Realisto ICO 
///
/// @author: Pavel Metelitsyn
/// September 2017




pragma solidity ^0.4.13;

import "./MiniMeToken.sol";
import "./library.sol";



// simple time locked vault 
// Controlled is implemented in MiniMeToken.sol
contract TokenVault is Controlled {
	using SafeMath for uint256;


	struct benificiary{

	}

	address campaignAddr;
	uint256 tUnlock;
	uint256 tDuration;
	MiniMeToken token;
	uint256 tExtractionWindow;
	uint256 maxExtractions;
	uint256 nExtractions = 0;
	uint256 availablePerPeriod;

	event Extract(address indexed _to, uint256 _amount);

	function TokenVault(
		address _tokenAddress,
	 	address _campaignAdress,
	 	address _owner,
	 	uint256 _tDuration,
	 	uint8 _maxExtractions
	 	) {
			campaignAddr = _campaignAdress;
			token = MiniMeToken(_tokenAddress);
			tDuration = _tDuration;
			tExtractionWindow = tDuration / maxExtractions;
		}

	/// unix time
	function setTimeLock(uint256 _tUnlock){
		require( msg.sender == campaignAddr );
		tUnlock = _tUnlock;
	}

	/// @notice Extracts all available Tokens to 
	function extract(address _to) onlyController{
		require ( (now >= tUnlock) &&
							(_to != 0x0) );

		// on first extraction
		// set how much is available per extraction 
		if (nExtractions == 0){
			availablePerPeriod = token.balanceOf(address(this)) / maxExtractions;
		}

		uint256 currentExtractionPeriod = 1 + ( now - tUnlock ) / tExtractionWindow;

		uint256 available = availablePerPeriod * (currentExtractionPeriod - nExtractions);
		require( token.transfer(_to, available) );
		nExtractions = currentExtractionPeriod;
		Extract(_to, available);

	}


	function extractRemaining(address _to) onlyController {
		require ( (now >= tUnlock + tDuration) &&
							(_to != 0x0) );

		uint256 available = token.balanceOf(address(this));
		require( token.transfer(_to, available) );
		Extract(_to, available);
	}

}