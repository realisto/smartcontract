#setting up fresh net

geth --datadir ~/.ethereum-private init genesis.json

The corresponding gesesis file is 

{
    "config": {
        "chainId": 22,
        "homesteadBlock": 0,
        "eip158Block": 0
    },
    "difficulty": "20000",
    "gasLimit": "2100000",
    "alloc": {
        "7df9a875a174b3bc565e6424a0050ebc1b2d1d82": { "balance": "300000" },
        "f41c74c9ae680c1aa78f42e5647a62f353b7bdde": { "balance": "400000" }
    }
}



in geth REPL:

# create new accounts
personal.newAccount(<password>)

#set etherbase





# to start local private testnet with eth

# 1 for a generic private net
geth --dev --maxpeers 0 --port 30304 --shh --rpc --rpcport 8545 --datadir ~/.ethereum-private --minerthreads 1 --rpccorsdomain "*" --rpcapi "eth,net,web3,personal,shh"

# 2 for a custom private net with id=22 generated from a genesis file
geth --maxpeers 0 --port 30304 --networkid 22 --shh --rpc --rpcport 8545 --datadir ~/.ethereum-private --minerthreads 1 --rpccorsdomain "*" --rpcapi "eth,net,web3,personal,shh"

###


# get repl attached to the private network

geth attach ipc://home/pm-master/.ethereum-private/geth.ipc



# start Mist and attach it to private network

mist --rpc /home/pm-master/.ethereum-private/geth.ipc 	




#### test rpc
// i dont use testrpc anymore

testrpc -s 65 -p 8546
EthereumJS TestRPC v4.0.1 (ganache-core: 1.0.1)

Available Accounts
==================
(0) 0xe6e9abcc047518a4aace3f6bf4d24756c9f37921
(1) 0x2406fd690e395ca476359357332209d90571be75
(2) 0xde5ec4bf232c0c79a863b24d2deb59079305db23
(3) 0xe3201f94da09260d5aa164b0cc728e5836b0e21e
(4) 0xc45169428df54cb67e6d298470b4000912a7bf9a
(5) 0x0b52aee63bfdeb328b7c8f3395aa3df9caae4c74
(6) 0x597cab2cf3ebce986c7f41fea5a599cf502182f2
(7) 0xb04c4c4ae377e6fd6c4683ac53c5ab4483e559d4
(8) 0x0120897f640db8ebcf84f3bc3a6a540325d0a868
(9) 0xb84d91972c08afa52dccb6f022d8ea2917da7be3

Private Keys
==================
(0) 1042f7a763330e57c9e7ff0866f26b25069f0dd2ae17bddad7fd06cfc21d35db
(1) d2ae586d0888b1f0845779bc7fbd81843d3930a5413762b8e57fd7deb49f4ce7
(2) cba2b56a510c38ac99919f6feb8c3c98c9331dcd2057eb65db03a5e2fc1d9ca5
(3) 309acf38290dc0f2cbf28bdf05364f78bf6fec7eb14a6901a0a5cffc89852a62
(4) 9c34519b0bd7c714b47991b31dfb2c4dfc5751039b509614f88efaa2073cc47a
(5) c39309d6c165247ff0667b8d6180aa6bef7b0c21484d59bfb802a34810434715
(6) e977cde4f25c74eaa8d972babc27c3ffd1616f3fd67278da5a0adc5a197add5a
(7) 6814183000dec21f96b8d899497f676bc99fb2cba5d119c11e2bca5a9e60d094
(8) 2688ae1fcc33795989586579dc7f58fce2dda45f146d3c787f268f1c0de6f999
(9) eb4d89cf6c142780712bf80d2aa07b866ebbe925ef5223a8e414df758c84401e

HD Wallet
==================
Mnemonic:      mirror perfect game shine flower control often twin deny era change obvious
Base HD Path:  m/44'/60'/0'/0/{account_index}


## Metamask Wallet: pribram48?
drastic daughter nominee much bubble initial game spike mandate you shove memeber


## MEW Test Wallet
Address: 0xfFDF31E7e1E82eceab7d47Db2203C4DeE609584d
password: myetherwallet
private key: 0a0f1401ed3a55265cfd5e5c55a5a3e799ae003e51b641a012785027cc9bc075
