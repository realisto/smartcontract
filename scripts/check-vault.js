// Print info
var colors = require('colors/safe');

var TokenVault = artifacts.require("TokenVault");	
var vault;

var bal, avail, tulock;

module.exports = function(callback){

	TokenVault.deployed()
		.then(
			function(instance){
				console.log(colors.red("# Vault at " + instance.address));
				vault = instance;})
		.then(function(){
				return Promise.all([
						vault.balance.call().then((x)=>{bal = x;}),
						vault.get_unlock_time.call().then((x)=>{tulock = x;}),
						vault.availableNow.call().then((x)=>{avail = x;})])})
		.then(function(){
				console.log(" balance: " + bal/1000000000000000000 );
				console.log(" available: " + avail/1000000000000000000);
				console.log(" time lock: " + tulock + "( in " + (tulock - Date.now()/1000)/60 + " minutes)");
			///	console.log(" time now: " Date.now());
		});
} 	

