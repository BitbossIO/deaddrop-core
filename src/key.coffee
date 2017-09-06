ecc = require 'ecc-tools'
Versions =
  btcmain: '00'

DefaultVersion = Versions.btcmain

class Key
  constructor: (key=ecc.privateKey(), @version=DefaultVersion) ->
    if !(@ instanceof Key) then return new Key(key)
    if (key instanceof Key) then return key

    @private = false
    @public = false
    @compressed = false
    @mutable = true

    key = Key.sanitize(key)

    switch @type = Key.type(key)
      when 'private' then @private = key
      when 'public' then  @public = key
      when 'compressed' then @compressed = key
      when 'hash' then @hash = key

    if @private then @public = ecc.publicKey(@private)
    if @public then @compressed = ecc.publicKeyConvert(@public, true)
    if @compressed and not @public then @public = ecc.publicKeyConvert(@compressed)
    if @compressed and not @hash then @hash = Key.hash(@compressed, @mutable)
    if @hash then @address = Key.address(@hash, @version)

  encoded: (type) -> ecc.encode(@[type])

Key.type = (key) ->
  key = Key.sanitize(key)
  if (key instanceof Buffer)
    switch key.length
      when 20 then 'hash'
      when 32 then 'private'
      when 33 then 'compressed'
      when 65 then 'public'

Key.sanitize = (key) ->
  key = ecc.decode(key) if typeof(key) is 'string'
  if (key instanceof Buffer)
    switch key.length
      when 20, 32, 33, 65 then key
      else throw new Error('invalid key')
  else throw new Error('invalid key')

Key.hash = (key) ->
  key = Key.sanitize(key)
  switch Key.type(key)
    when 'hash' then key
    when 'private' then Key.hash(ecc.publicKey(key, true))
    when 'public' then Key.hash(ecc.publicKeyConvert(key, true))
    when 'compressed' then ecc.rmd160(ecc.sha256(key))
    else throw new Error('invalid key')

Key.address = (key, version=DefaultVersion) ->
  ecc.encode(Buffer.concat([Key.version(version), Key.hash(key)]))

Key.version = (version) ->
  if typeof(version) is 'string'
    if Versions[version] then Key.version(Versions[version])
    else Buffer(version, 'hex')
  else if (version instanceof Buffer) then version
  else throw new Error('invalid version')

Key.equal = (first, second) ->
  Key(first).encoded('public') == Key(second).encoded('public')

module.exports = Key
