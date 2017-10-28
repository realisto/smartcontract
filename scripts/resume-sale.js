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
	
	var state;
	var returnCode;
	
	TokenCampaign.deployed().then(
		function(instance){
			console.log(colors.red("# Campaign at " + instance.address))
			console.log(colors.red("resume sale"))
			campaign = instance;
			return campaign.resumeSale()})
		.then(
			function(returnCode){
				
				console.log(" return code: " + returnCode );

			});  		
} 	



