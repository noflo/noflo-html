noflo = require 'noflo'
Flattener = require 'html-flatten'

class Flatten extends noflo.AsyncComponent
  icon: 'bars'
  constructor: ->
    @f = new Flattener()
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'
      error: new noflo.Port 'object'
    super()

  doAsync: (page, callback) ->
    if page.html and not page.items
      @f.processPage page, =>
        @outPorts.out.send page
        do callback
      return

    unless page.items?.length
      @outPorts.out.send page
      do callback
      return

    toDo = page.items.length

    for item in page.items
      @f.processPage item, =>
        toDo--
        return unless toDo is 0
        @outPorts.out.send page
        do callback

exports.getComponent = -> new Flatten
