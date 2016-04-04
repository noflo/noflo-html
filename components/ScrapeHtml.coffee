noflo = require 'noflo'
cheerio = require 'cheerio'

# @runtime noflo-nodejs

decode = (str) ->
  return str unless str.indexOf "&" >= 0
  return str.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&")

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Extract contents from HTML based on CSS selectors'
  c.ignoreSelectors = []

  c.inPorts.add 'in',
    datatype: 'string'
    description: 'HTML to scrape from'
  c.inPorts.add 'textselector',
    datatype: 'string'
    description: 'CSS selector to use'
  c.inPorts.add 'ignoreselector',
    datatype: 'string'
    process: (event, payload) ->
      return unless event is 'data'
      c.ignoreSelectors.push payload

  c.outPorts.add 'out',
    datatype: 'string'

  c.process (input, output) ->
    return unless input.has 'in', 'textselector'
    [data, textselector] = input.getData 'in', 'textselector'
    return unless input.ip.type is 'data'

    $ = cheerio.load data
    $(ignore).remove() for ignore in c.ignoreSelectors
    $(textselector).each (i,e) ->
      o = $(e)
      id = o.attr "id"

      if id?
        output.send
          out: new noflo.IP 'openBracket', id

      ip = new noflo.IP 'data', decode(o.text())
      ip.groups = [id]
      output.send
        out: ip

      if id?
        output.send
          out: new noflo.IP 'closeBracket', id
