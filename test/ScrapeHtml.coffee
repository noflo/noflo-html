scrape = require "../components/ScrapeHtml"
socket = require('noflo').internalSocket
chai = require 'chai'
expect = chai.expect

setupComponent = ->
  c = scrape.getComponent()
  ins = socket.createSocket()
  out = socket.createSocket()
  c.inPorts.in.attach ins
  c.outPorts.out.attach out
  [c, ins, out]

describe 'Scaping HTML', ->
  it 'test selector then html', (done) ->
    [c, ins, out] = setupComponent()
    s = socket.createSocket()
    c.inPorts.textselector.attach s
    expectdata = ["bar","baz"]
    out.once "begingroup", (group) ->
      fail "should not get groups without element ids"
    out.on "data", (data) ->
      expect(data).to.equal expectdata.shift()
      done() if expectdata.length == 0

    s.send "p.test"
    s.disconnect()
    ins.send '<div><p>foo</p><p class="test">bar</p><p class="test">baz</p></div>'
    ins.disconnect()

  it 'test html then selector', (done) ->
    [c, ins, out] = setupComponent()
    s = socket.createSocket()
    c.inPorts.textselector.attach s
    expectdata = ["bar","baz"]
    out.on "data", (data) ->
      expect(data).to.equal expectdata.shift()
      done() if expectdata.length == 0
    ins.send '<div><p>foo</p><p class="test">bar</p><p class="test">baz</p></div>'
    ins.disconnect()
    s.send "p.test"
    s.disconnect()

  it 'test ignore', (done) ->
    [c, ins, out] = setupComponent()
    s = socket.createSocket()
    i = socket.createSocket()
    c.inPorts.textselector.attach s
    c.inPorts.ignoreselector.attach i
    expectdata = ["foo"]
    out.on "data", (data) ->
      expect(data).to.equal expectdata.shift()
      done() if expectdata.length == 0
    i.send ".noise"
    i.send "#crap"
    i.disconnect()
    ins.send '<div><p class="test">foo</p><p id="crap" class="test">bar</p><p class="test noise">baz</p></div>'
    ins.disconnect()
    s.send "p.test"
    s.disconnect()

  it 'test group by element id', (done) ->
    [c, ins, out] = setupComponent()
    s = socket.createSocket()
    c.inPorts.textselector.attach s
    expectgroup = ["a","b"]
    expectdata = ["bar","baz"]
    chunks = []
    out.on "ip", (ip) ->
      if ip.type is 'data'
        chunks.push ip.data
        expect(ip.groups.join("")).to.equal expectgroup.shift()
      if ip.type is 'closeBracket'
        done() if expectgroup.length == 0

    s.send "p.test"
    s.disconnect()
    ins.send '<div><p>foo</p><p id="a" class="test">bar</p><p id="b" class="test">baz</p></div>'
    ins.disconnect()
