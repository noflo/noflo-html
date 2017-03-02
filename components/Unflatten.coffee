noflo = require 'noflo'
clone = require 'clone'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Return a flattened item structure to HTML'

  c.inPorts.add 'in',
    datatype: 'object'
  c.outPorts.add 'out',
    datatype: 'object'

  c.process (input, output) ->
    return unless input.hasData 'in'
    data = input.getData 'in'

    page = clone data
    page.content = [] unless page?.content

    page.html = page.content.map((block) -> block.html).join '\n'

    delete page.content

    output.sendDone
      out: page
