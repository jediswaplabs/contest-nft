import * as starkCurve from 'micro-starknet';
import { encode } from 'starknet';




const private_key = '0x019800ea6a9a73f94aee6a3d2edf018fc770443e90c7ba121e8303ec6b349279';
const account = '0x0138EfE7c064c69140e715f58d1e29FC75E5594D342E568246a4D6a3131a5974';
const pubKey = starkCurve.getStarkKey(private_key);
const task_id = '1';
const toke_id = '1024';
let hashMsg = starkCurve.pedersen(BigInt(account), BigInt(task_id));
hashMsg = starkCurve.pedersen(BigInt(hashMsg), BigInt(toke_id));
const signature = starkCurve.sign(hashMsg, private_key);
console.log("hashMsg: ", hashMsg);
console.log("signature r: ", encode.addHexPrefix(signature.r.toString(16)));
console.log("signature s: ", encode.addHexPrefix(signature.s.toString(16)));
console.log(" pubkey: ", pubKey);