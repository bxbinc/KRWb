import {encodeCall} from 'zos-lib'

export const sendTransaction = (target, method, args, values, opts) => {
    const data = encodeCall(method, args, values);
    return target.sendTransaction(Object.assign({data}, opts));
};
