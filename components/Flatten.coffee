noflo = require 'noflo'
Flattener = require 'html-flatten'
clone = require 'clone'

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'bars'
  c.inPorts.add 'in',
    datatype: 'object'
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  c.process (input, output) ->
    data = input.get 'in'
    return unless data.type is 'data'
    page = clone data.data

    f = new Flattener
    f.processPage page, (err, result) ->
      return output.sendDone err if err
      output.sendDone
        out: result
