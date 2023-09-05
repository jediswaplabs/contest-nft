import { merkle, num,cairo } from 'starknet';
import * as starkCurve from 'micro-starknet';
import * as fs from 'fs';

// read data from .csv file
// array of  [address, token_id, task_id, name, rank, score, level, total_eligible_users]

// let list = [['0x0138EfE7c064c69140e715f58d1e29FC75E5594D342E568246a4D6a3131a5974', 1, 1, parseInt(cairo.felt('L1P1')), 10, 12000, 6, 120000],
// ['0x02b9cE3e6869192006820c2B41c084BAB97f17DAe966b981dCA2FDae1C178065', 2, 1, parseInt(cairo.felt('L1P2')), 20, 11000, 6, 120000],
// ['0x0161A9bCA8dCc5975A03b12f5F7bF9610e1541635eb40eB3A89bAeeDC168e636', 3, 1, parseInt(cairo.felt('L1P1')), 320, 10000, 6, 120000],
// ['0x044F7CbDa8f82641C1F7D1b1a6BC56956d71acb4E0B51eEE742545b6aa08D0a0', 4, 1, parseInt(cairo.felt('L1P1')), 420, 9000, 6, 120000],
// ['0x0044B02486f7ED5D586b846094eD727b08E72B8C2eFa738293f3Ef864966514C', 5, 1, parseInt(cairo.felt('L1P1')), 520, 8000, 6, 120000],
// ['0x0138EfE7c064c69140e715f58d1e29FC75E5594D342E568246a4D6a3131a597E', 6, 1, parseInt(cairo.felt('L1P1')), 620, 7000, 6, 120000],
// ];
type Data = [string, number, number, number, number, number, number, number, string[]];
let list = fs.readFileSync('/home/felix/Downloads/median/output10_proof.txt', 'utf8').split('\n').map(line => {
    if (line === '') {
        return null;
    }
    const splitLine = line.split(',');

    const proofIndex = splitLine.findIndex((element) => element.includes('['));
    
    const proofString = splitLine.slice(proofIndex).join(',').trim();
    const proofArray = proofString.slice(1, proofString.length - 1).split(',').map(s => s.trim());
    
    let data: Data = [splitLine[0], parseInt(splitLine[1]), parseInt(splitLine[2]), parseInt(cairo.felt(splitLine[3])), parseInt(splitLine[4]), parseInt(splitLine[5]), parseInt(splitLine[6]), parseInt(splitLine[7]), proofArray];
    return data;
});
// remove the last item if it's an empty string
// if (list[list.length - 1].length === 1 && list[list.length - 1][0] === '') {
//     list.pop();
// }

let root = "0x364416474922e527188122afdfa40a0eb0ed046369ce6a2365dac91113fbee0";


// convert to aim list, each item is hash of two elements
// let aimList = list.map(item => {
//     let tmp =  starkCurve.pedersen(BigInt(item[0]),  BigInt(item[1]))
//     tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[2]))
//     tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[3]))
//     tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[4]))
//     tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[5]))
//     tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[6]))
//     tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[7]))

//     return tmp;
// })
// const tree = new merkle.MerkleTree(aimList);

// let i = 1;
// console.log("root = " + tree.root);

// for (let i of [1,2,3,4]) {
    
//     console.log("address = " + list[i][0])
    
    
//     console.log("token_id = " + list[i][1]);
    
//     console.log("proof = " + tree.getProof(aimList[i]))
    
    
//     console.log("token_metadata is " + list[i][2] + "," + cairo.felt(list[i][3]) + "," + list[i][4] + "," + list[i][5] + "," + list[i][6] + "," + list[i][7])
//     console.log("-----------------------------------------")
// }

// store each address to a map based on their last address digit
let map = new Map();
for (let i = 0; i < list.length; i++) {
    let lastDigit = (list[i][0] as string).slice(-1).toLowerCase();
    let data = {
                wallet_address: "0x" + (list[i][0] as string).toLowerCase().slice(2).replace(/^0+/, ''),
                wallet_address_int: BigInt(list[i][0]).toString(),
                calldata: list[i].slice(1, 8),
                proof: list[i][8]
    };
    if (map.has(lastDigit)) {
        map.get(lastDigit).push(data);
    } else {
        map.set(lastDigit, [data]);
    }
}

// write to file for each map item, and file name is the last digit
for (let [key, value] of map) {
    let fileName = key + ".json";
    let data = {
        root: root,
        data: value
    };
    fs.writeFile(fileName, JSON.stringify(data), function (err) {
        if (err) {
            return console.error(err);
        }
    });
}