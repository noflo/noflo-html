noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Return a flattened item structure to HTML'

  c.inPorts.add 'in',
    datatype: 'object'
  c.outPorts.add 'out',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'in'
    out: 'out'
    forwardGroups: true
  , (data, groups, out) ->
    data.content = [] unless data.content
    data.html = data.content.map((block) -> block.html).join '\n'
    delete data.content
    out.send data

  c
