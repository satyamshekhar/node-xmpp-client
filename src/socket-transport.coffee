EventEmitter = require("events").EventEmitter

tcp = require("net")
XmppParser = require("./xmpp-parser.coffee").XmppParser
clientUtils = require("./client-utils.coffee")

constants = require("./constants.coffee")

logFormat = "[TRANSPORT] %s"
log = clientUtils.log

class SocketTransport extends EventEmitter
    constructor: (@port, @host, @domain, @jid) ->
        @socket = new tcp.Socket()
        @parser = new XmppParser()
        @connected = false

        @openingStreamAttrs =
                to: @domain
                from: @jid
                version: 1.0
                xmlns: constants.XMPP_NS
                "xmlns:stream": constants.XMPP_STREAM_NS
                presenceStatus: "Test Client"
                "token": "AHNhdHlhbS5zAHNoZWtoYXIxMjMAUmFuZG9tTWV0YVRva2Vu"

        @_attachListenersToSocket()
        @_attachListenersToParser()

    connect: ()->
        @socket.connect @port, @host

    send: (data) ->
        throw "Not Connected" if not @connected

        try
            @socket.write data.toString()
            log "DEBUG", logFormat, "sent: #{data.toString()}"
        catch ex
            log "INFO", logFormat, ex.toString()
            @emit "error", ex

    restartStream: () ->
        throw "Not Connected" if not @connected
        @send clientUtils.makexml "stream:stream", @openingStreamAttrs

    terminate: () ->
        @socket.end?()
        @parser.end?()
        @connected = false
        @emit "disconnected"
        # clean up

    _attachListenersToParser: () ->
        @parser.on "stream-start", (attrs) =>
            log "DEBUG", logFormat, "server-stream-started"
            @emit "stream-started", attrs

        @parser.on "stream-restart", (attrs) =>
            log "DEBUG", logFormat, "server-stream-restart"
            @emit "stream-restarted", attrs

        @parser.on "stream-end", (attrs) =>
            log "DEBUG", logFormat, "server-stream-ended"
            @emit "stream-ended"
            @socket.end()

        @parser.on "stanza", (stanza) =>
            log "DEBUG", logFormat, "stanza"
            @emit "stanza", stanza

        @parser.on "error", (err) =>
            log "ERROR", logFormat, err
            @terminate()

    _attachListenersToSocket: () ->
        @socket.on "connect", () =>
            log "INFO", logFormat, "Connected"

            @connected = true
            @emit "connected"

            str = "<?xml version='1.0'?>"
            str += clientUtils.makexml "stream:stream", @openingStreamAttrs

            @send str

        @socket.on "error", (err) =>
            log "ERROR", logFormat, err

        @socket.on "data", (data) =>
            return if not @connected
            log "DEBUG", logFormat, "Received: #{data}"
            @parser.parse data

        @socket.on "close", (hadError) =>
            @connected = false
            @terminate()
            log "INFO", logFormat, "Socket closed"

############ exports ############

exports.SocketTransport = SocketTransport