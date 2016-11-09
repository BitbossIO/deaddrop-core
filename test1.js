var Dropstore = require('./lib/dropstore.js');
var Dropnet = require('./lib/dropnet.js');
var c0 = require('./test/fixtures/0.json')
var c1 = require('./test/fixtures/1.json')

var Test = {
  Dropstore: Dropstore,
  c0: c0,
  c1: c1,
  s0: () => {
    var ds = new Dropstore(c0.dropstore);
    return ds;
  },
  s1: () => {
    var ds = new Dropstore(c1.dropstore);
    ds.connect(c1.dropstore.seed);
    return ds;
  },
  n0: () => {
    var ds = Test.s0();
    var dn = new Dropnet(c0.dropnet, ds);
    return dn;
  },
  n1: () => {
    var ds = Test.s1();
    var dn = new Dropnet(c1.dropnet, ds);
    dn.connect(c1.dropnet.seed);
    return dn;
  },
  log: (e,m) => {
    if(e) {
      console.log('ERR:', e);
    } else {
      console.log('Value:', m);
    }
  }
};

module.exports = Test;
