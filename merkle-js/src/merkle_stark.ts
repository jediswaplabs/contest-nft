import { merkle, num,cairo } from 'starknet';
import * as starkCurve from 'micro-starknet';
import * as fs from 'fs';

// read data from .csv file
// array of  [address, token_id, task_id, name, rank, score, level, total_eligible_users]
let list = fs.readFileSync('/home/felix/Downloads/median/output10.csv', 'utf8').split('\n').map(item => item.split(','));

// convert to aim list, each item is hash of two elements
let aimList = list.map(item => {
    let tmp =  starkCurve.pedersen(BigInt(item[0]),  BigInt(item[1]))
    tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[2]))
    tmp = starkCurve.pedersen(BigInt(tmp),  num.toHex(cairo.felt(item[3])))
    tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[4]))
    tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[5]))
    tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[6]))
    tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[7]))

    return tmp;
})
const tree = new merkle.MerkleTree(aimList);

console.log(tree.root);

console.log(tree.getProof(aimList[0]))

// console.log(merkle.proofMerklePath(tree.root, '1', tree.getProof('1')))