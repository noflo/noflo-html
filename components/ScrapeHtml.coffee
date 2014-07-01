noflo = require "noflo"
cheerio = require "cheerio"

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

  noflo.helpers.WirePattern c,
    in: ['in', 'textselector']
    out: 'out'
    forwardGroups: true
  , (data, groups, out) ->
    $ = cheerio.load data.in
    $(ignore).remove() for ignore in c.ignoreSelectors
    $(data.textselector).each (i,e) ->
      o = $(e)
      id = o.attr "id"
      out.beginGroup id if id?
      out.send decode o.text()
      out.endGroup() if id?

  c
