noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  Flatten = require '../components/Flatten.coffee'
else
  Flatten = require 'noflo-html/components/Flatten.js'

describe 'Flatten component', ->
  c = null
  ins = null
  out = null
  beforeEach ->
    c = Flatten.getComponent()
    ins = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    c.inPorts.in.attach ins
    c.outPorts.out.attach out

  describe 'when instantiated', ->
    it 'should have an input port', ->
      chai.expect(c.inPorts.in).to.be.an 'object'
    it 'should have an output port', ->
      chai.expect(c.outPorts.out).to.be.an 'object'

  describe 'flattening HTML structures', ->
    it 'should be able to find a video and a paragraph', (done) ->
      if console.timeEnd
        console.time 'flattening HTML structures'
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          html: """
          <p>Hello world, <b>this</b> is some text</p>
          <video src="http://foo.bar"></video>
          <p class='pagination-centered'><img class='img-polaroid' src='http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png' /><img /></p>
          """
        ]

      expected =
        path: 'foo/bar.html'
        items: [
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
          ]
        ]

      out.on 'data', (data) ->
        if console.timeEnd
          console.timeEnd 'flattening HTML structures'
        chai.expect(data).to.eql expected
        done()
      ins.send sent

    it 'should be able to normalize video and image URLs', (done) ->
      if console.timeEnd
        console.time 'URL normalization'
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'http://bergie.iki.fi/blog/ingress-table/'
          html: """
          <p>Hello world, <b>this</b> is some text</p>
          <video src="/files/foo.mp4"></video>
          <p class='pagination-centered'><img class='img-polaroid' src='../../files/image.gif' /><img /></p>
          """
        ]

      expected =
        path: 'foo/bar.html'
        items: [
          id: 'http://bergie.iki.fi/blog/ingress-table/'
          content: [
            type: 'text'
            html: '<p>Hello world, <b>this</b> is some text</p>'
          ,
            type: 'video'
            video: 'http://bergie.iki.fi/files/foo.mp4'
            html: '<video src="http://bergie.iki.fi/files/foo.mp4"></video>'
          ,
            type: 'image'
            src: 'http://bergie.iki.fi/files/image.gif'
            html: '<img src="http://bergie.iki.fi/files/image.gif">'
          ]
        ]
      out.on 'data', (data) ->
        if console.timeEnd
          console.timeEnd 'URL normalization'
        chai.expect(data).to.eql expected
        done()
      ins.send sent

    it 'should retain groups', (done) ->
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          html: """
          <p>Hello world, <b>this</b> is some text</p>
          <video src="http://foo.bar"></video>
          """
        ]

      expected = ['foo', 'bar']
      found = []

      out.on 'begingroup', (group) ->
        found.push group
      out.on 'disconnect', ->
        chai.expect(found).to.eql expected
        done()
      ins.beginGroup grp for grp in expected
      ins.send sent
      ins.endGroup() for grp in expected
      ins.disconnect()

    it 'should be able to flatten a paragraph with only an image to an image', (done) ->
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          html: """
          <p><a href="http://foo.bar"><img src="http://foo.bar" alt="An image" title="My cool photo" data-foo="bar"></a></p>
          """
        ]

      expected =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          content: [
            type: 'image'
            src: 'http://foo.bar/'
            caption: 'My cool photo'
            html: '<a href="http://foo.bar/"><img src="http://foo.bar/" alt="An image" title="My cool photo" data-foo="bar"></a>'
          ]
        ]

      out.on 'data', (data) ->
        chai.expect(data).to.eql expected
        done()
      ins.send sent

    it 'should be able to flatten headlines and paragraphs', (done) ->
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          html: """
          <h1>Hello World</h1>
          <p class="intro">Some text</p>
          <h2 id="foo">Foo bar</h2>
          """
        ]

      expected =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          content: [
            type: 'headline'
            html: '<h1>Hello World</h1>'
          ,
            type: 'text'
            html: '<p>Some text</p>'
          ,
            type: 'headline'
            html: '<h2>Foo bar</h2>'
          ]
        ]

      if console.timeEnd
        console.time 'flattening headlines and paragraphs'
      out.on 'data', (data) ->
        if console.timeEnd
          console.timeEnd 'flattening headlines and paragraphs'
        chai.expect(data).to.eql expected
        done()
      ins.send sent

    it 'should be able to flatten lists', (done) ->
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          html: """
          <ul>
            <li>Hello world<ul>
              <li>Foo</li>
            </ul></li>
            <li>Foo bar</li>
          </ul>
          """
        ]

      expected =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          content: [
            type: 'list'
            html: '<ul><li>Hello world<ul><li>Foo</li></ul></li><li>Foo bar</li></ul>'
          ]
        ]

      if console.timeEnd
        console.time 'flattening lists'
      out.on 'data', (data) ->
        if console.timeEnd
          console.timeEnd 'flattening lists'
        chai.expect(data).to.eql expected
        done()
      ins.send sent

    it 'should be able to flatten things wrapped in divs', (done) ->
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          html: """
          <div>
          <ul>
            <li>Hello world<ul>
              <li>Foo</li>
            </ul></li>
            <li>Foo bar</li>
          </ul>
          </div>
          """
        ]

      expected =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          content: [
            type: 'list'
            html: '<ul><li>Hello world<ul><li>Foo</li></ul></li><li>Foo bar</li></ul>'
          ]
        ]

      if console.timeEnd
        console.time 'flattening lists'
      out.on 'data', (data) ->
        if console.timeEnd
          console.timeEnd 'flattening lists'
        chai.expect(data).to.eql expected
        done()
      ins.send sent

    it 'should be able to flatten things wrapped multiple levels of structural tags', (done) ->
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          html: """
          <div>
          <article>
          <span>
          <ul>
            <li>Hello world<ul>
              <li>Foo</li>
            </ul></li>
            <li>Foo bar</li>
          </ul>
          </span>
          </article>
          </div>
          """
        ]

      expected =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          content: [
            type: 'list'
            html: '<ul><li>Hello world<ul><li>Foo</li></ul></li><li>Foo bar</li></ul>'
          ]
        ]

      if console.timeEnd
        console.time 'flattening lists'
      out.on 'data', (data) ->
        if console.timeEnd
          console.timeEnd 'flattening lists'
        chai.expect(data).to.eql expected
        done()
      ins.send sent

    it 'should be able to discard useless content', (done) ->
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          html: """
          <p><span style=\"font-size: x-large;\"><br></br></span></p>
          <p>&nbsp;</p>
          <p><span style=\"font-size: large;\">Afterwards, we'll be running a dojo. No prior experience with FP is needed for this part; we'll all be coming from different levels. Our goals here are to equip you with a more of an understanding of functional programming and it's real-world applications and to learn from each other. More than all that: to have some fun with FP!</span></p>
          """
        ]

      expected =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          content: [
            type: 'text'
            html: '<p>Afterwards, we\'ll be running a dojo. No prior experience with FP is needed for this part; we\'ll all be coming from different levels. Our goals here are to equip you with a more of an understanding of functional programming and it\'s real-world applications and to learn from each other. More than all that: to have some fun with FP!</p>'
          ]
        ]

      if console.timeEnd
        console.time 'flattening formatting'
      out.on 'data', (data) ->
        if console.timeEnd
          console.timeEnd 'flattening formatting'
        chai.expect(data).to.eql expected
        done()
      ins.send sent

    it 'should be able to detect iframe videos', (done) ->
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          html: """
          <iframe src="//player.vimeo.com/video/72238422?color=ffffff" width="500" height="281" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
          <iframe src="//foo.bar.com/foo"></iframe>
          """
        ]

      expected =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          content: [
            type: 'video'
            video: '//player.vimeo.com/video/72238422?color=ffffff'
            html: '<iframe src="//player.vimeo.com/video/72238422?color=ffffff" width="500" height="281" frameborder="0" webkitallowfullscreen="webkitallowfullscreen" mozallowfullscreen="mozallowfullscreen" allowfullscreen="allowfullscreen"></iframe>'
          ,
            type: 'unknown'
            html: '<iframe src="//foo.bar.com/foo"></iframe>'
          ]
        ]

      if console.timeEnd
        console.time 'flattening iframes'
      out.on 'data', (data) ->
        if console.timeEnd
          console.timeEnd 'flattening iframes'
        chai.expect(data).to.eql expected
        done()
      ins.send sent

  describe 'flattening a partially pre-flattened page', ->
    it 'should keep the already flattened parts as they were', (done) ->
      sent =
        path: 'foo/bar.html'
        items: [
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
          ]
        ,
          id: 'new'
          html: """
          <p>Hello there</p>
          """
        ]
      expected =
        path: 'foo/bar.html'
        items: [
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
          ]
        ,
          id: 'new'
          content: [
            type: 'text'
            html: '<p>Hello there</p>'
          ]
        ]
      out.on 'data', (data) ->
        chai.expect(data).to.eql expected
        done()
      ins.send sent
