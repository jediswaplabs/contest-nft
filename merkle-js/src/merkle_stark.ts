import { merkle, num,cairo } from 'starknet';
import * as starkCurve from 'micro-starknet';
import * as fs from 'fs';

// read data from .csv file
// array of  [address, token_id, task_id, name, rank, score, level, total_eligible_users]
let list = [['0x0138EfE7c064c69140e715f58d1e29FC75E5594D342E568246a4D6a3131a5974', 1, 1, 'L1P1', 10, 12000, 6, 120000],
['0x02b9cE3e6869192006820c2B41c084BAB97f17DAe966b981dCA2FDae1C178065', 2, 1, 'L1P2', 20, 11000, 6, 120000],
['0x0161A9bCA8dCc5975A03b12f5F7bF9610e1541635eb40eB3A89bAeeDC168e636', 3, 1, 'L1P1', 320, 10000, 6, 120000],
['0x0044B02486f7ED5D586b846094eD727b08E72B8C2eFa738293f3Ef864966514C', 4, 1, 'L1P1', 420, 9000, 6, 120000],
['0x0138EfE7c064c69140e715f58d1e29FC75E5594D342E568246a4D6a3131a597a', 5, 1, 'L1P1', 520, 8000, 6, 120000],
['0x0138EfE7c064c69140e715f58d1e29FC75E5594D342E568246a4D6a3131a597E', 6, 1, 'L1P1', 620, 7000, 6, 120000],
];

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

let i = 3;

console.log("root = " + tree.root);

console.log("address = " + list[i][0])


console.log("token_id = " + list[i][1]);

console.log("proof = " + tree.getProof(aimList[i]))


console.log("token_metadata is " + list[i][2] + "," + cairo.felt(list[i][3]) + "," + list[i][4] + "," + list[i][5] + "," + list[i][6] + "," + list[i][7])

// console.log(merkle.proofMerklePath(tree.root, '1', tree.getProof('1')))