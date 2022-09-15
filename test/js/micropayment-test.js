import { createAlchemyWeb3 } from "@alch/alchemy-web3"
import { firestore } from '../../Settings.js'
import { getDoc, collection, updateDoc, doc } from 'firebase/firestore'
import contractABI from '../test-abi.json'
import abi from "ethereumjs-abi"
import eUtil from "ethereumjs-util"
// import contractABI from '../nft-abi.json'

const alchemyKey = "https://eth-ropsten.alchemyapi.io/v2/rbMCSk1QEzIwKvEPVEzlJquYNOqa9bWl"
const web3 = createAlchemyWeb3(alchemyKey)
const contractAddress = "0xc1D81f8be4AF8B446390384428EbC75B59246CDC"

async function testSign() {
    const from = window.ethereum.selectedAddress
    // const from = await web3.eth.getAccounts()
    const typedData = {
      domain: {
        chainId: 3,
        name: "DeNS",
        verifyingContract: contractAddress,
        version: "1"
      },
      message: {
        hash:
          "0x304daae8b785d35000cf209e65105a38339f539df7171fdbbec36a79abc2edf5",
        fee: "0.13 ETH",
        from: contractAddress,
        to: [{
          address: window.ethereum.selectedAddress,
          amount: "1ETH"
        }]
      },
      primaryType: "Bill",
      types: {
        EIP712Domain: [
          { name: "chainId", type: "uint256" },
          { name: "name", type: "string" },
          { name: "verifyingContract", type: "address" },
          { name: "version", type: "string" }
        ],
        Bill: [
          { name: "hash", type: "bytes32" },
          { name: "fee", type: "string" },
          { name: "from", type: "address" },
          { name: "to", type: "Output[]" }
        ],
        Output: [
          { name: "address", type: "string" },
          { name: "amount", type: "string" }
        ]
      }
    };
    window.ethereum.sendAsync(
        {
            method: "eth_signTypedData_v4",
            params: [from, JSON.stringify(typedData)],
            from
        },
        (err, r) => {
            console.log(err, r);
            alert(err ? err.message : r.result)
        }
    )
}

window.ethereum.enable().then(accounts => {
    // testSign()
})


// async function test() {
//     var hash = web3.utils.sha3("message to sign")
//     web3.eth.personal.sign(hash, web3.eth.defaultAccount, function () { console.log("Signed") })
// }

function constructPaymentMessage(recipient, contractAddress, amount, nonce) {
    return abi.soliditySHA3(
        ["address", "uint256", "uint256", "address"],
        [recipient, amount, nonce, contractAddress]
        // ["address", "uint256"],
        // [contractAddress, amount]
    )
}

async function signMessage(message, callback) {
    var signature = await web3.eth.personal.sign(
        "0x" + message.toString("hex"),
        // web3.eth.defaultAccount,
        window.ethereum.selectedAddress,
        callback
    )

    console.log(signature)
    var res = recoverSigner(message, signature)
    // console.log(res)
}

// contractAddress is used to prevent cross-contract replay attacks.
// amount, in wei, specifies how much Ether should be sent.
function signPayment(recipient, amount, nonce, contractAddress, callback) {
    var message = constructPaymentMessage(recipient, contractAddress, amount, nonce)
    signMessage(message, '')
}

// // this mimics the prefixing behavior of the eth_sign JSON-RPC method.
// function prefixed(hash) {
//     return abi.soliditySHA3(
//         ["string", "bytes32"],
//         ["\x19Ethereum Signed Message:\n32", hash]
//     )
// }

async function recoverSigner(message, signature) {
    // console.log(signature)
    console.log(eUtil)
    // var split = ethereumjs.Util.fromRpcSig(signature);
    // var publicKey = ethereumjs.Util.ecrecover(message, split.v, split.r, split.s);
    // var signer = ethereumjs.Util.pubToAddress(publicKey).toString("hex");
    // return signer;
}

// function isValidSignature(contractAddress, amount, signature, expectedSigner) {
//     var message = prefixed(constructPaymentMessage(contractAddress, amount));
//     var signer = recoverSigner(message, signature);
//     return signer.toLowerCase() ==
//         ethereumjs.Util.stripHexPrefix(expectedSigner).toLowerCase();
// }

// recipient is the address that should be paid.
// amount, in wei, specifies how much ether should be sent.
// nonce can be any unique number to prevent replay attacks
// contractAddress is used to prevent cross-contract replay attacks
// function signPayment(recipient, amount, nonce, contractAddress, callback) {
//     // var hash = web3.utils.sha3("message to sign")
//     var hash = "0x" + abi.soliditySHA3(
//         ["address", "uint256", "uint256", "address"],
//         [recipient, amount, nonce, contractAddress]
//     ).toString("hex")
    
//     web3.eth.personal.sign(hash, window.ethereum.selectedAddress, '');
// }

export { signPayment, testSign }