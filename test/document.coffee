chaiAsPromised = require 'chai-as-promised'
chai = require 'chai'

chai.use chaiAsPromised

expect = chai.expect

ecc = require 'ecc-tools'
Document = require '../src/document'

describe 'Document', ->
  before ->
    @private = ecc.privateKey()
    @public = ecc.publicKey(@private)
    @compressed = ecc.publicKey(@private, true)
    @encoded = ecc.encode(@public)
    @invalid = ecc.encode(Buffer(10))
    @address = '13AM4VW2dhxYgXeQepoHkHSQuy6NgaEb94'
    @data = {hello: 'world'}

  it 'should return an instance of Key', ->
    result = Document(@public)
    expect(result).to.be.an.instanceof(Document)

  describe 'instance', ->
    it 'should take private key and data', ->
      result = Document(@private, @data)
      expect(result.key.type).to.equal('private')

    describe 'envelope', ->
      it 'should return an envelope for a private key', ->
        result = Document(@private, @data).envelope()
        expect(result).to.be.an.instanceof(Document.Envelope)

      it 'should return the same envelope when called twice', ->
        document = Document(@private, @data)
        result = document.envelope()
        expect(result).to.equal(document.envelope())

    describe 'raw', ->
      it 'should return opened envelope', ->
        result = Document(@private, @data).raw()
        expect(result).to.eventually.have.all.keys('data', 'from')

    describe 'from', ->
      it 'should return envelope key', ->
        result = Document(@private, @data).from()
        expect(result).to.eventually.be.an.instanceof(Document.Key)

    describe 'data', ->
      it 'should return envelope data', ->
        result = Document(@private, @data).data()
        expect(result).to.eventually.have.all.keys('body', 'headers')

    describe 'headers', ->
      it 'should return envelope data', ->
        result = Document(@private, @data).headers()
        expect(result).to.eventually.have.all.keys('ttl', 'timestamp')

    describe 'ttl', ->
      it 'should default ttl to 3600', ->
        result = Document(@private, @data).ttl()
        expect(result).to.eventually.equal(3600)

    describe 'timestamp', ->
      it 'should default timestamp to current time', ->
        result = Document(@private, @data)._timestamp
        expect(result).to.equal(Date.now)

      it 'should set timestamp to timestamp argument', ->
        result = Document(@private, @data, 10, 20).timestamp()
        expect(result).to.eventually.equal(20)

      it 'should set timestamp to timestamp function', ->
        result = Document(@private, @data, 10, -> 20).timestamp()
        expect(result).to.eventually.equal(20)

    describe 'body', ->
      it 'should return envelope data', ->
        result = Document(@private, @data).body()
        expect(result).to.eventually.eql(@data)

    describe 'serialize', ->
      it 'should return an object', ->
        result = Document(@private, @data).serialize()
        expect(result).to.eventually.have.all.keys('version', 'hash', 'envelope')

