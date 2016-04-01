noflo = require 'noflo'
Flattener = require 'html-flatten'

exports.getComponent = ->
  c = new noflo.Component
    icon: 'bars'
    inPorts:
      in:
        datatype: 'object'
        required: true
    outPorts:
      out:
        datatype: 'object'
      error:
        datatype: 'object'

  c.process (input, output) ->
    return unless input.has 'in'
    data = input.getData 'in'
    return unless input.ip.type is 'data'

    f = new Flattener
    f.processPage data, (err, page) ->
      return output.sendDone err if err
      output.sendDone out: page
