noflo = require 'noflo'
htmlparser = require 'htmlparser'
uri = require 'URIjs'

class Flatten extends noflo.AsyncComponent
  icon: 'bars'
  structuralTags: [
    'div'
    'section'
    'span'
    'article'
    'header'
    'footer'
    'nav'
    'br'
    'meta'
    's'
  ]
  ignoredAttribs: [
    'id'
    'class'
    'data-query-source'
    'data-expanded-url'
    'target'
    'rel'
    'dir'
  ]
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'
      error: new noflo.Port 'object'
    super()

  doAsync: (page, callback) ->
    if page.html and not page.items
      @flattenItem page, =>
        @outPorts.out.send page
        do callback
      return

    unless page.items?.length
      @outPorts.out.send page
      do callback
      return

    toDo = page.items.length

    for item in page.items
      @flattenItem item, =>
        toDo--
        return unless toDo is 0
        @outPorts.out.send page
        do callback

  flattenItem: (item, callback) ->
    if item.content and not item.html
      # Already flattened
      do callback
      return

    unless item.html.match /^[\s]*</
      item.html = "<p>#{item.html}</p>"

    handler = new htmlparser.DefaultHandler (err, dom) =>
      item.content = []
      for tag in dom
        normalized = @normalizeTag tag, item.id
        continue unless normalized
        for block in normalized
          item.content.push block
      delete item.html
      do callback
    ,
      ignoreWhitespace: true
    parser = new htmlparser.Parser handler
    parser.parseComplete item.html

  normalizeUrl: (url, base) ->
    return url unless base
    parsed = uri url
    return url if parsed.protocol() in ['javascript', 'mailto']
    abs = parsed.absoluteTo(base).toString()
    abs

  normalizeTag: (tag, id) ->
    results = []

    if tag.type is 'text'
      results.push
        type: 'text'
        html: @tagToHtml tag, id
      return results

    if tag.name in @structuralTags
      return results unless tag.children
      for child in tag.children
        normalized = @normalizeTag child, id
        continue unless normalized
        results = results.concat normalized
      return results

    switch tag.name
      when 'video'
        tag.attribs.src = @normalizeUrl tag.attribs.src, id
        results.push
          type: 'video'
          video: tag.attribs.src
          html: @tagToHtml tag, id
      when 'iframe'
        return results unless tag.attribs
        tag.attribs.src = @normalizeUrl tag.attribs.src, id
        if tag.attribs.src.indexOf('vimeo.com') isnt -1 or tag.attribs.src.indexOf('youtube.com') isnt -1
          results.push
            type: 'video'
            video: tag.attribs.src
            html: @tagToHtml tag, id
        else
          results.push
            type: 'unknown'
            html: @tagToHtml tag, id
      when 'img'
        return results unless tag.attribs
        tag.attribs.src = @normalizeUrl tag.attribs.src, id
        if tag.attribs.src is 'http://en.wikipedia.org/wiki/Special:CentralAutoLogin/start?type=1x1'
          return results
        img =
          type: 'image'
          src: tag.attribs.src
          html: @tagToHtml tag, id
        if tag.attribs.title or tag.attribs.alt
          img.caption = tag.attribs.title or tag.attribs.alt
        results.push img
      when 'figure'
        return results unless tag.children
        type = 'image'
        src = undefined
        caption = null
        for child in tag.children
          if child.name is 'iframe'
            return @normalizeTag child, id
          if child.name is 'code'
            type = 'code'
          if child.name is 'img'
            if child.attribs
              child.attribs.src = @normalizeUrl child.attribs.src, id
              src = child.attribs.src
            type = 'image'
          if child.name is 'figcaption'
            caption = @tagToHtml child, id
        img =
          type: type
          src: src
          html: @tagToHtml tag, id
        if caption
          img.caption = caption
        results.push img
      when 'p', 'em', 'small'
        return unless tag.children
        hasContent = false
        normalized = []
        for child in tag.children
          if child.name is 'video'
            normalized = normalized.concat @normalizeTag child, id
          else if child.name is 'img'
            normalized = normalized.concat @normalizeTag child, id
          else if child.name is 'a' and tag.children.length is 1
            normalized = normalized.concat @normalizeTag child, id
          else
            hasContent = true
        # If we only have images or videos inside, then return them
        # as individual items
        return normalized unless hasContent

        # If we have other stuff too, then return them as-is
        html = @tagToHtml tag, id
        return results if html is '<p></p>'
        results.push
          type: 'text'
          html: html
      when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
        results.push
          type: 'headline'
          html: @tagToHtml tag, id
      when 'pre'
        results.push
          type: 'code'
          html: @tagToHtml tag, id
      when 'ul', 'ol', 'dl'
        results.push
          type: 'list'
          html: @tagToHtml tag, id
      when 'blockquote'
        results.push
          type: 'quote'
          html: @tagToHtml tag, id
      when 'table'
        results.push
          type: 'table'
          html: @tagToHtml tag, id
      when 'time'
        results.push
          type: 'time'
          html: @tagToHtml tag, id
      when 'a'
        return results unless tag.children
        if tag.attribs
          tag.attribs.href = @normalizeUrl tag.attribs.href, id
        normalizedChild = @normalizeTag tag.children[0], id
        return results unless normalizedChild.length
        normalizedChild[0].html = @tagToHtml tag, id
        return normalizedChild
      # Tags that we ignore entirely
      when 'form', 'input', 'textarea', 'aside', 'button', 'meta', 'script', 'hr', 'br'
        return results
      else
        results.push
          type: 'unknown'
          html: @tagToHtml tag, id
    results

  tagToHtml: (tag, id) ->
    if tag.type is 'text'
      return '' unless tag.data
      return '' if tag.data.trim() is ''
      return '' if tag.data is '&nbsp;'
      return tag.data
    if tag.name in @structuralTags or tag.name is 'figcaption'
      return '' unless tag.children
      content = ''
      for child in tag.children
        content += @tagToHtml child, id
      return content

    attributes = ''
    if tag.attribs
      for attrib, val of tag.attribs
        continue if attrib in @ignoredAttribs
        if tag.name is 'a' and attrib is 'href'
          val = @normalizeUrl val, id
        if tag.name is 'img' and attrib is 'src'
          val = @normalizeUrl val, id
        attributes += " #{attrib}=\"#{val}\""
    html = "<#{tag.name}#{attributes}>"
    if tag.children
      content = ''
      for child in tag.children
        content += @tagToHtml child, id
      html += content
    if tag.name isnt 'img'
      html += "</#{tag.name}>"
    return html

exports.getComponent = -> new Flatten
