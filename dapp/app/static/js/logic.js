//or u could initialize like this
const serverUrl = "https://vnxt2uhutuem.usemoralis.com:2053/server";
const appId = "5kDFWpUkqb9flCuQO32KhxFmNsQSmAKfcmPJgP8E";
Moralis.start({serverUrl, appId});

//Humaverse nft address on rinkeby
const nft_contract_address = "0x098f2e79a5F6858aAE064342a8bFb09D5630659D" //NFT Minting Contract Use This One "Batteries Included", code of this contract is in the github repository under contract_base for your reference.
/*
Other Available deployed contracts
Ethereum Rinkeby 0x0Fb6EF3505b9c52Ed39595433a21aF9B5FCc4431
Polygon Mumbai 0x351bbee7C6E9268A1BF741B098448477E08A0a53
BSC Testnet 0x88624DD1c725C6A95E223170fa99ddB22E1C6DDD
*/

const web3 = new Web3(window.ethereum);

//frontend logic

async function login(){
  document.getElementById('login').setAttribute("disabled", null);
  await Moralis.Web3.authenticate({signingMessage:"Welcome Dog Boy"}).then(async function (user) {
      address = user.get('ethAddress');
      let options = {chain: "rinkeby", address: address};
      let balance = await Moralis.Web3API.account.getNativeBalance(options);
      document.getElementById("balance").innerHTML = balance['balance']/ 10**18;
      //document.getElementById("logOut").removeAttribute("disabled");
      document.getElementById("amount").removeAttribute("disabled");
      document.getElementById("upload").removeAttribute("disabled");
  })
}

function ethtoSend(){
  const amount = document.getElementById("amount").value;
  const calc = amount * 0.08;
  document.getElementById("ethvalue").innerHTML = `<p>Amount of Eth used(@0.08/NFT) is:${calc}</p>`
};


async function logOut(){
  await Moralis.User.logOut();
  console.log('User logged out');
  document.getElementById('login').removeAttribute("disabled");
}

async function upload(){
  ethtoSend();
  const amount = document.getElementById("amount").value;
  let Value = amount * 0.08;
  console.log(`Eth value is ${Value}`)
  const ethValue = `${Value}`
  const txt = await mintToken(amount, ethValue).then(notify);
  console.log(txt);
  logOut();
}

async function mintToken(amount, ethValue){
  const encodedFunction = web3.eth.abi.encodeFunctionCall({
    name: "mintToken",
    type: "function",
    stateMutability: "payable",
    inputs: [{
      "name": "numberOfNFTs",
      "type": "uint256"
      }]
  }, [amount]);

  //nftMint = web3.eth.contract(nft_contract_address, abi = nftAbi)


  const transactionParameters = {
    to: nft_contract_address,
    from: ethereum.selectedAddress,
    data: encodedFunction,
    value: web3.utils.toHex(web3.utils.toWei(ethValue, 'ether'))//'100000000000000'
  };
  const txt = await ethereum.request({
    method: 'eth_sendTransaction',
    params: [transactionParameters],

  });
  return txt
}

async function notify(_txt){
  document.getElementById("resultSpace").innerHTML =  
  `<input disabled = "true" id="result" type="text" class="form-control" placeholder="Description" aria-label="URL" aria-describedby="basic-addon1" value="Your NFT was minted in transaction ${_txt}">`;
} 

//getNFT = async()=>{}
async function getNFT(){
  console.log('get nfts clicked')
  let user = Moralis.User.current();
  nfts = await Moralis.Web3API.account.getNFTs({chain: 'rinkeby'});
  console.log(nfts);
  tableOfNFTs = document.getElementById('tableOfNFTs');

  if (nfts.result.length>0){
      //for (let i=0; i<nfts.result.length; i++){}
      nfts.result.forEach(n => {
          console.log(JSON.parse(n.metadata));
          let metadata = JSON.parse(n.metadata);
          let content = `
          <div class="card col-md-3">
              <img src = "${fixUrl(metadata.image)}" class="card-img-top">
              <div class="card-body">
                  <h5 class="card-title">${metadata.name}</h5>
                  <p class="card-text">${metadata.description}</p>
              </div>
          </div>
          `
          tableOfNFTs.innerHTML += content;
      })
      
  }
}

//function fixUrl(url){
fixUrl = (url)=>{
  //if (url != null){
  if (url.startsWith ("ipfs")){
    return "https://ipfs.moralis.io:2053/ipfs/" + url.split("ipfs://").slice(-1);
  }else{
      return url + "?format=json";
  }
  //}
  
}


//document.getElementById("login").onclick = login();