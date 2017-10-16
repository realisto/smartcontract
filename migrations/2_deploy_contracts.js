var colors = require('colors/safe');


var Token = artifacts.require("RealistoToken");
var Campaign = artifacts.require("TokenCampaign");
var TokenFactory = artifacts.require("MiniMeTokenFactory");
var TokenVault = artifacts.require("LinearTokenVault")

var issuerAddr = '0x09280db720fa5a3b7c08af4d1cff760f21b075d4';
var trusteeAddr = '0x863352e9b120686df29f3b5ad963ff53c4275934';

var teamAddr = '0xE2fa819dFd9a2ddD7354E5E122b0B493B97B894A';
var reserveAddr = '0x99a033C2C6fBE8159177B815457e8E66c4D759FE';
var bountyAddr = '0xE664F98e4929379b648A3D1733a2579ABafaAE20';
var robotAddr = '0xF7Ab4F8212331f74c07F1351B456E562Da827Dbc';
var opAddr = '0xE40213F88F577a58dc26990c71F45abCce4134c9';

var tokenAddr;
var campaignAddr;

function post_deploy(){
	Token.at(tokenAddr)
		.then(
			function(instance){
				instance.setGenerateAddr(campaignAddr);			
			});

}


module.exports = function(deployer, network, accounts) {
	var issuer = issuerAddr;
	var trustee = trusteeAddr;
	var controller = issuer;
	var token_version = 1;

	console.log(colors.black.bgYellow("The network is " + network));
	

	console.log("The token contract will be issued from address " + issuer);
	console.log("Setting trustee address to " + trustee);
	console.log("Setting campaign controller to " + controller);
	console.log("Setting team address to " + teamAddr);
	

	deployer.deploy(TokenFactory)
		.then(
			function(){
				var tokenFactoryAddr = TokenFactory.address;
				console.log(colors.yellow.bold("##! Token factory contract deployed at " + tokenFactoryAddr));
				return deployer.deploy(Token, tokenFactoryAddr);})
		.then(
			function(){
				tokenAddr = Token.address;
				console.log(colors.yellow.bold("##! Token  contract deployed at " + tokenAddr));
				return deployer.deploy(Campaign, 
					tokenAddr,
					teamAddr,
					trusteeAddr,
					opAddr,
					bountyAddr,
					reserveAddr,
					robotAddr);})
		.then(
			function(){
				campaignAddr = Campaign.address;
				console.log(colors.yellow.bold("##! Campaign contract deployed at \n    " + campaignAddr));
				
				//console.log("Set token generator to contract's address..");
				console.log("Performing post deploy actions...")
					post_deploy();
				
				
				});
		
			
};

