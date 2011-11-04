ltx = require("ltx")
expat = require("node-expat")

EventEmitter = require("events").EventEmitter

class XmppParser extends EventEmitter
    constructor: () ->
        @parser = new expat.Parser "UTF-8"
        @root = null

        @_started = false

        @parser.on "startElement", @_handleStartElement
        @parser.on "endElement", @_handleEndElement
        @parser.on "text", @_handleTextNode



    _handleStartElement: (name, attrs) =>
        if not @_started
            if name is "stream:stream"
                @_started = true
                @root = new ltx.Element name, attrs
                @emit "stream-start", attrs
            else
                @parser.stop()
                @emit "error", "stanza without a stream start"
        else
            if name is "stream:stream"
                @root = new ltx.Element name, attrs
                @emit "stream-restart", attrs
            else
                element = new ltx.Element name, attrs
                @_element = if @_element then @_element.cnode element else element

    _handleEndElement: (name, attrs) =>
        if name is "stream:stream"
            @emit "stream-end", attrs
            return

        if @_element.parent is null
            @_element.parent = @root
            @emit "stanza", @_element
            delete @_element
        else
            @_element = @_element.parent


    _handleTextNode: (text) =>
        @_element.t text if @_element

    parse: (data) ->
        if not @parser.parse data
            @emit "error", @parser.getError()

    end: ->
        @parser.stop()
        @parser.removeAllListeners "startElement"
        @parser.removeAllListeners "endElement"
        @parser.removeAllListeners "text"

exports.XmppParser = XmppParser