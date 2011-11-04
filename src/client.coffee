EventEmitter = require("events").EventEmitter
util = require("util")

SocketTransport = require("./socket-transport.coffee").SocketTransport
constants = require("./constants.coffee")
clientUtils = require("./client-utils.coffee")

ConnectionStates = constants.ConnectionStates
PresenceStates = constants.PresenceStates

logFormat = "[CLIENT] %s"
log = clientUtils.log

XMPP_NS = constants.XMPP_NS
XMPP_STREAM_NS = constants.XMPP_STREAM_NS

# jid:
# domain:
# resource:
# host:
# port:
# presence: /* optional */
#
# _state:
#   connectionState:
#   transport:

parsePresence = (presence) ->
    return null if not presence
    presence = presence.toLowerCase?()
    switch presence
        when "available" then return PresenceStates.AVAILABLE
        when "busy" then return PresenceStates.BUSY
        when "away" then return PresenceStates.AWAY
        when "offline" then return PresenceStates.OFFLINE
        else return null

stateToActionMap = { }
stateToActionMap[ConnectionStates.DISCONNECTED] = (stanza, client) ->
    log "ERROR", logFormat, "received #{stanza} when disconnected"
    client.emit "error", "Not Connected"

stateToActionMap[ConnectionStates.CONNECTING] = (stanza, client) ->
    log "DEBUG", logFormat, "CONNECTING received: #{stanza}"

    if not stanza.is "features"
        log "ERROR", logFormat, "Didn't received stream:features when connecting"
        client._terminate()
        return

    mechanisms = stanza.getChild "mechanisms", constants.XMPP_SASL_NS

    if not mechanisms
        log "ERROR", logFormat, "No mechanisms recvd"
        client._terminate()
        return

    mechanisms = mechanisms.getChildren "mechanism"
    console.log mechanisms
    supportsPlain = (true for mechanism in mechanisms when mechanism.getText() is "PLAIN")

    if supportsPlain
        client._transport.send "<auth xmlns='#{constants.XMPP_SASL_NS}' mechanism='PLAIN-PW'/>"
        client._connectionState = ConnectionStates.AUTH_MECH_SELECTED

stateToActionMap[ConnectionStates.AUTH_MECH_SELECTED] = (stanza, client) ->
    console.log "To Implement"

stateToActionMap[ConnectionStates.AUTHENTICATING] = (stanza, client) ->
    console.log "To Implement"

stateToActionMap[ConnectionStates.AUTHENTICATED] = (stanza, client) ->
    console.log "To Implement"

stateToActionMap[ConnectionStates.BINDING_RESOURCE] = (stanza, client) ->
    console.log "To Implement"

stateToActionMap[ConnectionStates.ESTABLISHING_SESSION] = (stanza, client) ->
    console.log "To Implement"

stateToActionMap[ConnectionStates.CONNECTED] = (stanza, client) ->
    console.log "To Implement"


login = (client) ->
    client._transport.connect()

class XmppClient extends EventEmitter
    constructor: (args) ->
        if !(args and args.jid and args.domain and args.host)
            @emit "error", "Insufficient Params to init client"

        @jid = args.jid
        @domain = args.domain
        @resource = args.resource || null
        @host = args.host
        @port = args.port || 5222
        @presence = parsePresence(args.presence) || PresenceStates.AVAILABLE

        @_initState()
        @_attachHandlers()

    _initState: () ->
        @_connectionState = ConnectionStates.DISCONNECTED
        @_transport = new SocketTransport @port, @host, @domain, @jid

    _attachHandlers: () ->
        @_transport.on "connected", () =>
            @_connectionState = ConnectionStates.CONNECTING
            log "INFO", logFormat, "Connected"

        @_transport.on "stream-started", (attrs) =>
            console.log util.inspect attrs
            console.log attrs.xmlns + " " + constants.XMPP_NS
            console.log attrs["xmlns:stream"] + " " + constants.XMPP_STREAM_NS
            if attrs.xmlns isnt constants.XMPP_NS or attrs["xmlns:stream"] isnt constants.XMPP_STREAM_NS
                log "ERROR", logFormat, "wrong ns in opening stream"
                @_terminate()

            if Math.floor attrs.version < 1.0
                log "ERROR", logFormat, "version < 1.0 not supported"
                @_transport.terminate()

        @_transport.on "disconnected", () =>
            @_connectionState = ConnectionStates.DISCONNECTED
            log "INFO", logFormat, "Disconnected"

        @_transport.on "stanza", (stanza) =>
            log "DEBUG", logFormat, "stanza: #{util.inspect stanza} state: #{@_connectionState}"
            stateToActionMap[@_connectionState] stanza, this

    _terminate: () ->
        @_transport.terminate()


    login: () ->
        login this

    logout: () ->
        logout this

    setPresence: () ->
        setPresence this

    sendMessage: (message) ->

############ exports ############

exports.XmppClient = XmppClient




