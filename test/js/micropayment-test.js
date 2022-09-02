import { createAlchemyWeb3 } from "@alch/alchemy-web3"
import { firestore } from '../../Firebase.js'
import { getDoc, collection, updateDoc, doc } from 'firebase/firestore'
import contractABI from '../test-abi.json'
import abi from "ethereumjs-abi"
// import contractABI from '../nft-abi.json'

const alchemyKey = "https://eth-ropsten.alchemyapi.io/v2/rbMCSk1QEzIwKvEPVEzlJquYNOqa9bWl"
const web3 = createAlchemyWeb3(alchemyKey)
const contractAddress = "0xc1D81f8be4AF8B446390384428EbC75B59246CDC"


// window.ethereum.enable().then(accounts => {
//     const from = accounts[0]
//     const typedData = {
//         domain: {
//             chainId: 1,
//             name: "ckb.pw",
//             verfifyingContract: "0xc1D81f8be4AF8B446390384428EbC75B59246CDC",
//             version: "1"
//         },
//         message: {
//             hash: "0x304daae8b785d35000cf209e65105a38339f539df7171fdbbec36a79abc2edf5",
//             fee: "0.00000509CKB",
//             "input-sum": "99899.99999491CKB",
//             to: [
//                 {
//                     address: "ckt1qny...ufs62l5",
//                     amount: "100.0000000CKB"
//                 },
//                 {
//                     address: "ckt1qny...ufs62l5",
//                     amount: "99799.99999491CKB"
//                 }
//             ]
//         },
//         primaryType: "CKBTransaction",
//         types: {
//             EIP721Domain: [
//                 {
//                     name: "name",
//                     type: "string"
//                 },
//                 {
//                     name: "version",
//                     type: "string"
//                 },
//                 {
//                     name: "chainId",
//                     type: "uint256"
//                 },
//                 {
//                     name: "verifyingContract",
//                     type: "address"
//                 }
//             ],
//             CKBTransaction: [
//                 {
//                     name: "hash",
//                     type: "bytes32"
//                 },
//                 {
//                     name: "fee",
//                     type: "string"
//                 },
//                 {
//                     name: "input-sum",
//                     type: "string"
//                 },
//                 {
//                     name: "to",
//                     type: "Output[]"
//                 }
//             ],
//             Output: [
//                 {
//                   name: "address",
//                   type: "string"
//                 },
//                 {
//                   name: "amount",
//                   type: "string"
//                 }
//               ]
//         }
//     }

//     window.ethereum.Async(
//         {
//             method: "eth_signTypedData_v4",
//             params: [from, JSON.stringify(typedData)],
//             from
//         },
//         (err, r) => {
//             console.log(err, r);
//             alert(err ? err.message : r.result)
//         }
//     )
// })


// async function test() {
//     var hash = web3.utils.sha3("message to sign")
//     web3.eth.personal.sign(hash, web3.eth.defaultAccount, function () { console.log("Signed") })
// }

function constructPaymentMessage(contractAddress, amount) {
    return abi.soliditySHA3(
        ["address", "uint256"],
        [contractAddress, amount]
    )
}

function signMessage(message, callback) {
    web3.eth.personal.sign(
        "0x" + message.toString("hex"),
        web3.eth.defaultAccount,
        callback
    )
}

// contractAddress is used to prevent cross-contract replay attacks.
// amount, in wei, specifies how much Ether should be sent.
function signPayment(contractAddress, amount, callback) {
    var message = constructPaymentMessage(contractAddress, amount)
    signMessage(message, callback)
}

// this mimics the prefixing behavior of the eth_sign JSON-RPC method.
function prefixed(hash) {
    return abi.soliditySHA3(
        ["string", "bytes32"],
        ["\x19Ethereum Signed Message:\n32", hash]
    )
}

function recoverSigner(message, signature) {
    var split = ethereumjs.Util.fromRpcSig(signature);
    var publicKey = ethereumjs.Util.ecrecover(message, split.v, split.r, split.s);
    var signer = ethereumjs.Util.pubToAddress(publicKey).toString("hex");
    return signer;
}

function isValidSignature(contractAddress, amount, signature, expectedSigner) {
    var message = prefixed(constructPaymentMessage(contractAddress, amount));
    var signer = recoverSigner(message, signature);
    return signer.toLowerCase() ==
        ethereumjs.Util.stripHexPrefix(expectedSigner).toLowerCase();
}

export { signPayment }

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

//     web3.eth.personal.sign(hash, web3.eth.defaultAccount, callback);
// }