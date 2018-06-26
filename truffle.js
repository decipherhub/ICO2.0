require('babel-register')({
    ignore: /node_modules\/(?!openzeppelin-solidity\/test\/helpers)/
});
require('babel-polyfill');
module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "*",
            gasPrice: 0 // this is necessary for dev
        }
    }
};
