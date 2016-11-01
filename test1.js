var DHT = require('./lib/dht.js');
var c0 = require('./test/fixtures/0.json')
var c1 = require('./test/fixtures/1.json')

var Test = {
  DHT: DHT,
  c0: c0,
  c1: c1,
  i0: () => {
    var dht = new DHT(c0);
    return dht;
  },
  i1: () => {
    var dht = new DHT(c1);
    dht.connect(c1.seed);
    return dht;
  }
};

module.exports = Test;
