noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-html'

describe 'ScrapeHtml component', ->
  c = null
  selector = null
  ignore = null
  ins = null
  out = null
  before (done) ->
    @timeout 6000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'html/ScrapeHtml', (err, instance) ->
      return done err if err
      c = instance
      selector = noflo.internalSocket.createSocket()
      ignore = noflo.internalSocket.createSocket()
      ins = noflo.internalSocket.createSocket()
      c.inPorts.textselector.attach selector
      c.inPorts.ignoreselector.attach ignore
      c.inPorts.in.attach ins
      done()
  beforeEach ->
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
  afterEach ->
    c.outPorts.out.detach out

  describe 'with selector, then HTML', ->
    it 'should return the textual data', (done) ->
      expected = [
        'DATA bar'
        'DATA baz'
      ]
      received = []

      out.on 'begingroup', (grp) ->
        received.push "< #{grp}"
      out.on 'data', (data) ->
        received.push "DATA #{data}"
      out.on 'endgroup', ->
        received.push '>'
      out.on 'disconnect', ->
        chai.expect(received).to.eql expected
        done()

      selector.send 'p.test'
      selector.disconnect()
      ins.send '<div><p>foo</p><p class="test">bar</p><p class="test">baz</p></div>'
      ins.disconnect()

  describe 'with HTML, then selector', ->
    it 'should return the textual data', (done) ->
      expected = [
        'DATA bar'
        'DATA baz'
      ]
      received = []

      out.on 'begingroup', (grp) ->
        received.push "< #{grp}"
      out.on 'data', (data) ->
        received.push "DATA #{data}"
      out.on 'endgroup', ->
        received.push '>'
      out.on 'disconnect', ->
        chai.expect(received).to.eql expected
        done()

      ins.send '<div><p>foo</p><p class="test">bar</p><p class="test">baz</p></div>'
      ins.disconnect()
      selector.send 'p.test'
      selector.disconnect()

  describe 'with ignore selector', ->
    it 'should return only the non-ignored textual data', (done) ->
      expected = [
        'DATA foo'
      ]
      received = []

      out.on 'begingroup', (grp) ->
        received.push "< #{grp}"
      out.on 'data', (data) ->
        received.push "DATA #{data}"
      out.on 'endgroup', ->
        received.push '>'
      out.on 'disconnect', ->
        chai.expect(received).to.eql expected
        done()

      ignore.send ".noise"
      ignore.send "#crap"
      ignore.disconnect()
      ins.send '<div><p class="test">foo</p><p id="crap" class="test">bar</p><p class="test noise">baz</p></div>'
      ins.disconnect()
      selector.send 'p.test'
      selector.disconnect()

  describe 'with element ID', ->
    it 'should return the textual data with groups', (done) ->
      expected = [
        '< a'
        'DATA bar'
        '>'
        '< b'
        'DATA baz'
        '>'
      ]
      received = []

      out.on 'begingroup', (grp) ->
        received.push "< #{grp}"
      out.on 'data', (data) ->
        received.push "DATA #{data}"
      out.on 'endgroup', ->
        received.push '>'
      out.on 'disconnect', ->
        chai.expect(received).to.eql expected
        done()

      selector.send 'p.test'
      selector.disconnect()
      ins.send '<div><p>foo</p><p id="a" class="test">bar</p><p id="b" class="test">baz</p></div>'
      ins.disconnect()
