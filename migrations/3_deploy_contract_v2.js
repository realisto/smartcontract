var colors = require('colors/safe');
var inq = require('inquirer');


var Token = artifacts.require("Token_v2");
var Campaign = artifacts.require("TokenCampaign");
var TokenFactory = artifacts.require("MiniMeTokenFactory");

var issuerAddr = '0x09280db720fa5a3b7c08af4d1cff760f21b075d4';
var trusteeAddr = '0x863352e9b120686df29f3b5ad963ff53c4275934';
var campaignDuration = 600;

var tokenAddr;
var campaignAddr;

function post_deploy(){
	Token.at(tokenAddr)
		.then(
			function(instance){
				instance.allow_generate(campaignAddr);			
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
	console.log("Setting campaign duration to " + campaignDuration + " seconds");
	

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
				return deployer.deploy(Campaign, tokenAddr, trusteeAddr, issuerAddr, campaignDuration);})
		.then(
			function(){
				campaignAddr = Campaign.address;
				console.log(colors.yellow.bold("##! Campaign contract deployed at \n    " + campaignAddr));
				console.log("Set token generator to contract's address..");
				
				post_deploy();
				
				
				});
		
			
};

