noflo = require 'noflo'
Flattener = require 'html-flatten'

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'bars'
  c.inPorts.add 'in',
    datatype: 'object'
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'in'
    out: 'out'
    async: true
    forwardGroups: true
  , (data, groups, out, callback) ->
    f = new Flattener
    f.processPage data, (err, page) ->
      return callback err if err
      out.send page
      do callback
