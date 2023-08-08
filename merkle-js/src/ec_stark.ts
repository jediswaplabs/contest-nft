import * as starkCurve from 'micro-starknet';
import { merkle, num,cairo, encode } from 'starknet';

// array of  [address, token_id, task_id, name, rank, score, percentile, level, total_eligible_users]
let list = [['0x0138EfE7c064c69140e715f58d1e29FC75E5594D342E568246a4D6a3131a5974', 1, 1, 'L1P1', 10, 12000, 1, 6, 120000]];
const private_key = '0x019800ea6a9a73f94aee6a3d2edf018fc770443e90c7ba121e8303ec6b349279';
const pubKey = starkCurve.getStarkKey(private_key);


let aimList = list.map(item => {
    let tmp =  starkCurve.pedersen(BigInt(item[0]),  BigInt(item[1]))
    tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[2]))
    tmp = starkCurve.pedersen(BigInt(tmp),  num.toHex(cairo.felt(item[3])))
    tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[4]))
    tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[5]))
    tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[6]))
    tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[7]))
    tmp = starkCurve.pedersen(BigInt(tmp),  BigInt(item[8]))

    return tmp;
})

const signature = starkCurve.sign(aimList[0], private_key);
console.log("hashMsg: ", aimList[0]);
console.log("signature r: ", encode.addHexPrefix(signature.r.toString(16)));
console.log("signature s: ", encode.addHexPrefix(signature.s.toString(16)));
console.log(" pubkey: ", pubKey);