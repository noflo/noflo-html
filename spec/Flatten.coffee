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

  describe 'flattening HTML structures inside item', ->
    it 'should be able to find a video and a paragraph', (done) ->
      sent =
        id: 'main'
        html: """
        <script>alert('foo');</script>
        <p>Hello world, <b>this</b> is some text</p>
        <video src="http://foo.bar"></video>
        <video autoplay="true" loop="true" controls="false">
          <source type="video/mp4" src="//s3-us-west-2.amazonaws.com/cdn.thegrid.io/posts/cta-ui-bg.mp4"/>
          <source type="video/webm" src="//s3-us-west-2.amazonaws.com/cdn.thegrid.io/posts/cta-ui-bg.webm"/>
        </video>
        <p class='pagination-centered'><img class='img-polaroid' src='http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png' /><img /></p>
        <p><button data-uuid="71bfc2e0-4a96-11e4-916c-0800200c9a66" data-role="cta" data-verb="purchase" data-price="96">Buy now</button></p>
        """

      expected =
        id: 'main'
        content: [
          type: 'text'
          html: '<p>Hello world, <b>this</b> is some text</p>'
          text: 'Hello world, this is some text'
        ,
          type: 'video'
          video: 'http://foo.bar/'
          html: '<video src="http://foo.bar/"></video>'
        ,
          type: 'video'
          html: '<video autoplay="true" loop="true" controls="false"><source type="video/mp4" src="//s3-us-west-2.amazonaws.com/cdn.thegrid.io/posts/cta-ui-bg.mp4"><source type="video/webm" src="//s3-us-west-2.amazonaws.com/cdn.thegrid.io/posts/cta-ui-bg.webm"></video>'
        ,
          type: 'image'
          src: 'http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png'
          html: '<img src="http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png">'
        ,
          type: 'cta'
          uuid: '71bfc2e0-4a96-11e4-916c-0800200c9a66'
          verb: 'purchase'
          price: '96'
          html: '<button data-uuid="71bfc2e0-4a96-11e4-916c-0800200c9a66" data-role="cta" data-verb="purchase" data-price="96">Buy now</button>'
        ]

      out.on 'data', (data) ->
        chai.expect(data).to.eql expected
        done()
      ins.send sent
      ins.disconnect()

  describe 'flattening HTML structures', ->
    it 'should be able to find a video and an image inside figures', (done) ->
      if console.timeEnd
        console.time 'flattening HTML structures'
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          html: """
          <p>Hello world, <b>this</b> is some text</p>
          <figure><iframe frameborder="0" src="http://www.youtube.com/embed/YzC7MfCtkzo"></iframe></figure>
          <figure><img alt=\"An illustration of NoFlo used to create a flow-based version of the Jekyll tool for converting text into content suitable for Web publishing.\" src=\"http://cnet3.cbsistatic.com/hub/i/r/2013/09/10/92df7aec-6ddf-11e3-913e-14feb5ca9861/resize/620x/929f354f66ca3b99ab045f6f15a6693a/noflo-jekyll.png\">An illustration of NoFlo used to create a flow-based version of the Jekyll tool for converting text into content suitable for Web publishing.</figure>
          <figure><div><img src=\"http://timenewsfeed.files.wordpress.com/2012/02/slanglol.jpg?w=480&amp;h=320&amp;crop=1\"></div>\n<figcaption><small>Tom Turley / <a href=\"http://www.gettyimages.com/\">Getty Images</a></small></figcaption></figure>
          """
        ]

      expected =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          content: [
            type: 'text'
            html: '<p>Hello world, <b>this</b> is some text</p>'
            text: 'Hello world, this is some text'
          ,
            type: 'video'
            video: 'http://www.youtube.com/embed/YzC7MfCtkzo'
            html: '<iframe frameborder="0" src="http://www.youtube.com/embed/YzC7MfCtkzo"></iframe>'
          ,
            type: 'image'
            src: 'http://cnet3.cbsistatic.com/hub/i/r/2013/09/10/92df7aec-6ddf-11e3-913e-14feb5ca9861/resize/620x/929f354f66ca3b99ab045f6f15a6693a/noflo-jekyll.png'
            html: '<figure><img alt=\"An illustration of NoFlo used to create a flow-based version of the Jekyll tool for converting text into content suitable for Web publishing.\" src=\"http://cnet3.cbsistatic.com/hub/i/r/2013/09/10/92df7aec-6ddf-11e3-913e-14feb5ca9861/resize/620x/929f354f66ca3b99ab045f6f15a6693a/noflo-jekyll.png\">An illustration of NoFlo used to create a flow-based version of the Jekyll tool for converting text into content suitable for Web publishing.</figure>'
          ,
            type: 'image'
            src: 'http://timenewsfeed.files.wordpress.com/2012/02/slanglol.jpg?w=480&amp;h=320&amp;crop=1'
            caption: 'Tom Turley / <a href="http://www.gettyimages.com/">Getty Images</a>'
            html: "<figure><img src=\"http://timenewsfeed.files.wordpress.com/2012/02/slanglol.jpg?w=480&amp;h=320&amp;crop=1\"><figcaption>Tom Turley / <a href=\"http://www.gettyimages.com/\">Getty Images</a></figcaption></figure>"
          ]
        ]

      out.on 'data', (data) ->
        if console.timeEnd
          console.timeEnd 'flattening HTML structures'
        chai.expect(data).to.eql expected
        done()
      ins.send sent
      ins.disconnect()

    it 'should be able to find Embed.ly videos and audios', (done) ->
      if console.timeEnd
        console.time 'flattening HTML structures'
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          html: """
          <p>Hello world, <b>this</b> is some text</p>
          <iframe class=\"embedly-embed\" src=\"//cdn.embedly.com/widgets/media.html?src=http%3A%2F%2Fwww.youtube.com%2Fembed%2F8Dos61_6sss%3Ffeature%3Doembed&url=http%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3D8Dos61_6sss&image=http%3A%2F%2Fi.ytimg.com%2Fvi%2F8Dos61_6sss%2Fhqdefault.jpg&key=internal&type=text%2Fhtml&schema=youtube\" width=\"500\" height=\"281\" scrolling=\"no\" frameborder=\"0\" allowfullscreen></iframe>
          <iframe class=\"embedly-embed\" src=\"//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fw.soundcloud.com%2Fplayer%2F%3Fvisual%3Dtrue%26url%3Dhttp%253A%252F%252Fapi.soundcloud.com%252Ftracks%252F153760638%26show_artwork%3Dtrue&url=http%3A%2F%2Fsoundcloud.com%2Fsupersquaremusic%2Fanywhere-everywhere-super-square-original&image=http%3A%2F%2Fi1.sndcdn.com%2Fartworks-000082002645-fhibur-t500x500.jpg%3Fe76cf77&key=internal&type=text%2Fhtml&schema=soundcloud\" width=\"500\" height=\"500\" scrolling=\"no\" frameborder=\"0\" allowfullscreen></iframe>
          """
        ]

      expected =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          content: [
            type: 'text'
            html: '<p>Hello world, <b>this</b> is some text</p>'
            text: 'Hello world, this is some text'
          ,
            type: 'video'
            video: '//cdn.embedly.com/widgets/media.html?src=http%3A%2F%2Fwww.youtube.com%2Fembed%2F8Dos61_6sss%3Ffeature%3Doembed&url=http%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3D8Dos61_6sss&image=http%3A%2F%2Fi.ytimg.com%2Fvi%2F8Dos61_6sss%2Fhqdefault.jpg&key=internal&type=text%2Fhtml&schema=youtube'
            html: '<iframe src=\"//cdn.embedly.com/widgets/media.html?src=http%3A%2F%2Fwww.youtube.com%2Fembed%2F8Dos61_6sss%3Ffeature%3Doembed&url=http%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3D8Dos61_6sss&image=http%3A%2F%2Fi.ytimg.com%2Fvi%2F8Dos61_6sss%2Fhqdefault.jpg&key=internal&type=text%2Fhtml&schema=youtube\" width=\"500\" height=\"281\" scrolling=\"no\" frameborder=\"0\" allowfullscreen></iframe>'
          ,
            type: 'audio'
            video: '//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fw.soundcloud.com%2Fplayer%2F%3Fvisual%3Dtrue%26url%3Dhttp%253A%252F%252Fapi.soundcloud.com%252Ftracks%252F153760638%26show_artwork%3Dtrue&url=http%3A%2F%2Fsoundcloud.com%2Fsupersquaremusic%2Fanywhere-everywhere-super-square-original&image=http%3A%2F%2Fi1.sndcdn.com%2Fartworks-000082002645-fhibur-t500x500.jpg%3Fe76cf77&key=internal&type=text%2Fhtml&schema=soundcloud'
            html: '<iframe src=\"//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fw.soundcloud.com%2Fplayer%2F%3Fvisual%3Dtrue%26url%3Dhttp%253A%252F%252Fapi.soundcloud.com%252Ftracks%252F153760638%26show_artwork%3Dtrue&url=http%3A%2F%2Fsoundcloud.com%2Fsupersquaremusic%2Fanywhere-everywhere-super-square-original&image=http%3A%2F%2Fi1.sndcdn.com%2Fartworks-000082002645-fhibur-t500x500.jpg%3Fe76cf77&key=internal&type=text%2Fhtml&schema=soundcloud\" width=\"500\" height=\"500\" scrolling=\"no\" frameborder=\"0\" allowfullscreen></iframe>'
          ]
        ]

      out.on 'data', (data) ->
        if console.timeEnd
          console.timeEnd 'flattening HTML structures'
        chai.expect(data).to.eql expected
        done()
      ins.send sent
      ins.disconnect()

    it 'should be able to find images inside paragraphs', (done) ->
      if console.timeEnd
        console.time 'flattening HTML structures'
      sent =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          html: """
          <p>Hello world, <b>this</b> is some text</p>
          <p>Another exciting new product is <a href="http://noflojs.org/">NoFlo,</a> a flow-based Javascript programming tool. Developed as the result of a successful Kickstarter campaign (disclosure: I was a backer), it highlights both the dissatisfaction with the currently available tools, and the untapped potential for flow-based programming tools, that could be more easily understood by non-programmers. NoFlo builds upon Node.js to deliver functional apps to the browser. Native output to Android and iOS is in the works.<a href="http://noflojs.org/"><img src="http://netdna.webdesignerdepot.com/uploads/2014/07/0091.jpg" alt=""></a></p>
          """
        ]

      expected =
        path: 'foo/bar.html'
        items: [
          id: 'main'
          content: [
            type: 'text'
            html: '<p>Hello world, <b>this</b> is some text</p>'
            text: 'Hello world, this is some text'
          ,
            type: 'text'
            html: '<p>Another exciting new product is <a href="http://noflojs.org/">NoFlo,</a> a flow-based Javascript programming tool. Developed as the result of a successful Kickstarter campaign (disclosure: I was a backer), it highlights both the dissatisfaction with the currently available tools, and the untapped potential for flow-based programming tools, that could be more easily understood by non-programmers. NoFlo builds upon Node.js to deliver functional apps to the browser. Native output to Android and iOS is in the works.</p>'
            text: 'Another exciting new product is NoFlo, a flow-based Javascript programming tool. Developed as the result of a successful Kickstarter campaign (disclosure: I was a backer), it highlights both the dissatisfaction with the currently available tools, and the untapped potential for flow-based programming tools, that could be more easily understood by non-programmers. NoFlo builds upon Node.js to deliver functional apps to the browser. Native output to Android and iOS is in the works.'
          ,
            type: 'image'
            src: 'http://netdna.webdesignerdepot.com/uploads/2014/07/0091.jpg'
            html: '<a href="http://noflojs.org/"><img src="http://netdna.webdesignerdepot.com/uploads/2014/07/0091.jpg" alt=""></a>'
          ]
        ]

      out.on 'data', (data) ->
        if console.timeEnd
          console.timeEnd 'flattening HTML structures'
        chai.expect(data).to.eql expected
        done()
      ins.send sent
      ins.disconnect()
