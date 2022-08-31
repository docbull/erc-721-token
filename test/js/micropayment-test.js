import { createAlchemyWeb3 } from "@alch/alchemy-web3"
import { firestore } from '../../Firebase.js'
import { getDoc, collection, updateDoc, doc } from 'firebase/firestore'
import contractABI from '../test-abi.json'
import abi from "ethereumjs-abi"
// import contractABI from '../nft-abi.json'

const alchemyKey = "https://eth-ropsten.alchemyapi.io/v2/rbMCSk1QEzIwKvEPVEzlJquYNOqa9bWl"
const web3 = createAlchemyWeb3(alchemyKey)
const contractAddress = "0xc1D81f8be4AF8B446390384428EbC75B59246CDC"

// async function test() {
//     var hash = web3.utils.sha3("message to sign")
//     web3.eth.personal.sign(hash, web3.eth.defaultAccount, function () { console.log("Signed") })
// }

// recipient is the address that should be paid.
// amount, in wei, specifies how much ether should be sent.
// nonce can be any unique number to prevent replay attacks
// contractAddress is used to prevent cross-contract replay attacks
function signPayment(recipient, amount, nonce, contractAddress, callback) {
    // var hash = web3.utils.sha3("message to sign")
    var hash = "0x" + abi.soliditySHA3(
        ["address", "uint256", "uint256", "address"],
        [recipient, amount, nonce, contractAddress]
    ).toString("hex")

    web3.eth.personal.sign(hash, web3.eth.defaultAccount, callback);
}