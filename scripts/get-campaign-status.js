// Print info
var colors = require('colors/safe');

var TokenCampaign = artifacts.require("TokenCampaign");	

var stateNames = ["finalized, not accepting funds",
				  "closed, not accepting funds", 
				  "active, main sale, accepting funds",
				  "active, pre-sale ?",
				  "passive, not accepting funds"]; 


module.exports = function(callback){
	var campaign;
	var controller;
	var trustee;
	var team;
	var tokenAddr;
	var raised, available, generated;
	var rate;
	var state;
	var minc;
	var isBonus;

	
	TokenCampaign.deployed().then(
		function(instance){
			console.log(colors.blue("# Campaign at " + instance.address))
			campaign = instance;
		})
		.then(
			function(){
				return Promise.all([
				


					//campaign.availableTokens.call().then(
					//	(x)=>{available = x}),

					//campaign.tokenController.call().then(
					//	(x)=>{controller = x}),


					
					campaign.trusteeVaultAddr.call().then(
						(x)=>{trustee = x}),

					campaign.tokenAddr.call().then(
						(x)=>{tokenAddr = x}),

					
					campaign.teamVaultAddr.call().then(
						(x)=>{team = x}),

					campaign.decimals.call().then(
						(x)=>{decimals = x}),

					campaign.scale.call().then(
						(x)=>{scale = x}),

					campaign.minContribution.call().then(
						(x)=>{minc = x/1000000000000000000}),

					campaign.get_rate.call().then(
						(x)=>{rate = x}),

					campaign.tCampaignEnd.call().then(
						(x)=>{tEnd = x}),

					campaign.tokensGenerated.call().then(
						(x)=>{generated = x}),

					campaign.amountRaised.call().then(
						(x)=>{raised = x/1000000000000000000}),

					campaign.campaignState.call().then(
						(x)=>{state = x})])
			})
		.then(
			function(){

				console.log(colors.white.bold("# Campaign State: " + state + " - (" + stateNames[state] +")"));
				console.log(" Parameters:")
				console.log("   Controller: " + controller);
				console.log("   Token: " + tokenAddr);
				console.log("   Trustee: " + trustee)	;	
				console.log("   Team: " + team);	
				console.log(" scale:" + scale);
				console.log(" decimals: " + decimals );
				console.log(" min contribution: " + minc );
				console.log(" Generated Tokens: " + generated );
				console.log(" Current rate:" + rate);
				console.log(" Funds raised: " + raised);
				var secondsLeft = (tEnd - Date.now()/1000);
				var minutesLeft = secondsLeft/60;
				var hoursLeft = minutesLeft/60
				console.log(" Ends in: " + tEnd + " (" + (tEnd - Date.now()/1000) + " = " + minutesLeft + " minutes )" );

				//console.log("   Allow generate: " + allowGen);	
			});  		
} 	



