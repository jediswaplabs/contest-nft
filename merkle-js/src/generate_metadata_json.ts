import { merkle, num,cairo } from 'starknet';
import * as starkCurve from 'micro-starknet';
import * as fs from 'fs';

// read data from .csv file
// array of  [address, token_id, task_id, name, rank, score, level, total_eligible_users, proof]
type Data = [string, number, number, string, number, number, number, number, string[]];
let list = fs.readFileSync('/home/felix/Downloads/median/output10_proof.txt', 'utf8').split('\n').map(line => {
    if (line === '') {
        return null;
    }
    const splitLine = line.split(',');

    const proofIndex = splitLine.findIndex((element) => element.includes('['));
    
    const proofString = splitLine.slice(proofIndex).join(',').trim();
    const proofArray = proofString.slice(1, proofString.length - 1).split(',').map(s => s.trim());
    
    let data: Data = [splitLine[0], parseInt(splitLine[1]), parseInt(splitLine[2]), splitLine[3], parseInt(splitLine[4]), parseInt(splitLine[5]), parseInt(splitLine[6]), parseInt(splitLine[7]), proofArray];
    return data;
});

let dir_prefix = '/home/felix/Downloads/median/ipfs-json/';

let cid_prefix = 'https://static.missions.jediswap.xyz/static-nft/high-definition/';
let cid_suffix = '.png';

let anmation_url_prefix = 'https://static.missions.jediswap.xyz/3d-animated-nft/';
let animation_url_suffix = '.mp4';

// make dir if not exist
if (!fs.existsSync(dir_prefix)) {
    fs.mkdirSync(dir_prefix);
}

for (let i = 0; i < list.length; i++) {
    const item = list[i];
    const fileName = `${i + 1}`;
    const data = {
        name: 'Rise of the First LPs',
        description: 'A JediSwap NFT won during the 100 days long 1st LP contest.',
        image: cid_prefix + item[3].toLowerCase() + cid_suffix,
        animation_url: anmation_url_prefix + item[3].toLowerCase() + animation_url_suffix,
        attributes: [
            {
                trait_type: 'task_id',
                value: item[2]
            },
            {
                trait_type: 'name',
                value: item[3]
            },
            {
                trait_type: 'rank',
                value: item[4]
            },
            {
                trait_type: 'score',
                value: item[5]
            },
            {
                trait_type: 'level',
                value: item[6]
            }
        ]
    };
    fs.writeFileSync(dir_prefix + fileName, JSON.stringify(data));
}

// // write to file for each map item, and file name is the last digit
// for (let [key, value] of map) {
//     let fileName = key + ".json";
//     let data = {
//         root: root,
//         data: value
//     };
//     fs.writeFile(fileName, JSON.stringify(data), function (err) {
//         if (err) {
//             return console.error(err);
//         }
//     });
// }