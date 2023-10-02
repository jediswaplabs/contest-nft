import { merkle, num,cairo } from 'starknet';
import * as starkCurve from 'micro-starknet';
import * as fs from 'fs';

type Data = [string, number, number, number, number, number, number, number, string[]];

// notice: change the root to your own root
let root = "0x364416474922e527188122afdfa40a0eb0ed046369ce6a2365dac91113fbee0";
// read list from file,
// file format: address, token_id, task_id, name, rank, score, level, total_eligible_users, proof
// notice: replace the file path to your own file path
let list = fs.readFileSync('./example/example.txt', 'utf8').split('\n').map(line => {
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