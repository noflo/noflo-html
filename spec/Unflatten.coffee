noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-html'

describe 'Unflatten component', ->
  c = null
  ins = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'html/Unflatten', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      c.inPorts.in.attach ins
      done()
  beforeEach ->
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
  afterEach ->
    c.outPorts.out.detach out

  describe 'when instantiated', ->
    it 'should have an input port', ->
      chai.expect(c.inPorts.in).to.be.an 'object'
    it 'should have an output port', ->
      chai.expect(c.outPorts.out).to.be.an 'object'

  describe 'unflattening HTML structures inside item', ->
    it 'should return the HTML string', (done) ->
      expected =
        id: 'main'
        html: """
        <p>Hello world, <b>this</b> is some text</p>
        <video src="http://foo.bar/"></video>
        <img src="http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png">
        <article><h1>Apple</h1><p>The <b>apple</b> is the pomaceous fruit of the apple tree...</p></article>
        """

      sent =
        id: 'main'
        content: [
          type: 'text'
          html: '<p>Hello world, <b>this</b> is some text</p>'
        ,
          type: 'video'
          video: 'http://foo.bar/'
          html: '<video src="http://foo.bar/"></video>'
        ,
          type: 'image'
          src: 'http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png'
          html: '<img src="http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png">'
        ,
          type: 'article'
          html: "<article><h1>Apple</h1><p>The <b>apple</b> is the pomaceous fruit of the apple tree...</p></article>"
          title: 'Apple'
          caption: 'The <b>apple</b> is the pomaceous fruit of the apple tree...'
        ]

      out.on 'data', (data) ->
        chai.expect(data).to.eql expected
        done()
      ins.send sent
