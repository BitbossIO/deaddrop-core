_ = require 'lodash'

chaiAsPromised = require 'chai-as-promised'
chai = require 'chai'

chai.use chaiAsPromised

expect = chai.expect

ecc = require 'ecc-tools'
Key = require '../src/key'

describe 'Key', ->
  before ->
    @private = Buffer("e6129aa837003db95ee6b3b3ed244b86008e14c6ac49796664643a111a4802bf", 'hex')
    @public = ecc.publicKey(@private)
    @compressed = ecc.publicKey(@private, true)
    @hash = ecc.rmd160(ecc.sha256(@compressed))

    @encoded = ecc.encode(@public)
    @invalid = ecc.encode(Buffer(10))
    @address = '17tEZTEaAhqzcujf5DyNTCh1WwSqB2WmNC'

  it 'should return an instance of Key', ->
    result = Key(@public)
    expect(result).to.be.an.instanceof(Key)

  describe 'type', ->
    it 'should return "private" for a private key', ->
      result = Key.type(@private)
      expect(result).to.equal('private')

    it 'should return "public" for a public key', ->
      result = Key.type(@public)
      expect(result).to.equal('public')

    it 'should return "compressed" for a compressed public key', ->
      result = Key.type(@compressed)
      expect(result).to.equal('compressed')

    it 'should return "unknown" for an invalid key', ->
      f = => Key.type(2)
      expect(f).to.throw()

  describe 'sanitize', ->
    it 'should return a buffer for a base58check encoded string', ->
      result = Key.sanitize(@encoded)
      expect(result).to.be.an.instanceof(Buffer)

    it 'should error for an invalid key', ->
      f = => Key.sanitize(@invalid)
      expect(f).to.throw()

  describe 'address', ->
    it 'should take a hash and return an address', ->
      result = Key.address(Key.hash(@compressed))
      expect(result).to.be.equal(@address)

    it 'should take a private key and return an address', ->
      result = Key.address(@private)
      expect(result).to.be.equal(@address)

    it 'should take a public key and return an address', ->
      result = Key.address(@public)
      expect(result).to.be.equal(@address)

    it 'should take a compressed public key and return an address', ->
      result = Key.address(@compressed)
      expect(result).to.be.equal(@address)
