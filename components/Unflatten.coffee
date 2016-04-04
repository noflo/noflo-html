noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Return a flattened item structure to HTML'

  c.inPorts.add 'in',
    datatype: 'object'
  c.outPorts.add 'out',
    datatype: 'object'

  c.process (input, output) ->
    return unless input.has 'in'
    data = input.getData 'in'
    return unless input.ip.type is 'data'

    data.content = [] unless data.content
    data.html = data.content.map((block) -> block.html).join '\n'
    delete data.content
    output.sendDone out: data
