EventEmitter = require("events").EventEmitter
util = require("util")


auth = require("./auth.coffee")
builder = require("builder.coffee")
constants = require("./constants.coffee")
clientUtils = require("./client-utils.coffee")
SocketTransport = require("./socket-transport.coffee").SocketTransport

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
#   _state:
#   _transport:


class XmppClient extends EventEmitter
    constructor: (args) ->
        if !(args and args.jid and args.domain and args.host and args.password)
            @emit "error", "Insufficient Params to init client"

        @jid = args.jid
        @password = args.password
        @domain = args.domain
        @resource = args.resource || null
        @host = args.host
        @port = args.port || 5222
        @presence = clientUtils.parsePresence(args.presence) || PresenceStates.AVAILABLE

        @_init()

    _init: () ->
        @_state = ConnectionStates.DISCONNECTED
        @_transport = new SocketTransport @port, @host, @domain, @jid
        @_attachTransportHandlers()

    _isValidStream: (attrs) =>
        if attrs.xmlns isnt constants.XMPP_NS or attrs["xmlns:stream"] isnt constants.XMPP_STREAM_NS
            log "ERROR", logFormat, "wrong ns in opening stream"
            return false

        else if Math.floor attrs.version < 1.0
            log "ERROR", logFormat, "version < 1.0 not supported"
            return false

        else return true

    _handleStreamStart: (attrs) =>

        if @_isValidStream attrs then @_transport.on "stanza", @_handleStreamFeatures
        else @_terminate()

    _handleConnect: () =>
        @_state = ConnectionStates.CONNECTING
        log "INFO", logFormat, "Socket Estb."

    _handleDisconnect: () =>
        @_state = ConnectionStates.DISCONNECTED
        log "INFO", logFormat, "Disconnected"

    _attachTransportHandlers: () ->
        @_transport.on "connected", @_handleConnect
        @_transport.on "stream-started", @_handleStreamStart
        @_transport.on "stream-restarted", @_handleStreamStart
        @_transport.on "disconnected", @_handleDisconnect

    _handleAuthentication: (stanza) =>
        authMechanisms = stanza.getChild "mechanisms", constants.XMPP_SASL_NS
        return if not authMechanisms
        authHandler = auth.authenticate this, authMechanisms

        if not authHandler
            log "ERROR", logFormat, "Mechanism not supported."
            @_terminate()
            return

        authFailureHandler = () =>
            log "INFO", logFormat, "Auth failure"
            @emit "authentication-failure"
            @_terminate()

        authSuccessHandler = () =>
            log "INFO", logFormat, "Authenticated"
            @emit "authenticated"
            @_transport.restartStream()

        authErrorHandler = (err) =>
            log "ERROR", logFormat, "auth-error: #{err}"
            @_terminate()

        authHandler.on "failure", authFailureHandler
        authHandler.on "success", authSuccessHandler
        authHandler.on "error", authErrorHandler

    _handleResourceBinding: (features) =>
        bind = features.getChild "bind", constants.XMPP_BIND_NS
        return if not bind

        bind = builder.bind @resource

        bindResponseHandler = (stanza) =>
            isBindResponse = (stanza) ->
                r = stanza.is "iq"
                s = stanza.attrs.id is bind.attrs.id
                t = stanza.attrs.type is "result"
                return r and s and t

            return if not isBindResponse stanza

            @_transport.removeListener "stanza", bindResponseHandler

            error = stanza.getChild "error"
            if error
                log "ERROR", logFormat, "bind: #{error}"
                @_terminate()
                return

            bindResponse = stanza.getChild "bind", constants.XMPP_BIND_NS
            jid = bindResponse.getChild "jid"
            jid = jid.getText()

            @resource = clientUtils.resourceFromJid jid
            log "INFO", logFormat, "Resource: #{@resource}"

        @_transport.on "stanza", bindResponseHandler
        @_transport.send bind.toString()

    _handleSessionBinding: (features) =>
        session = features.getChild "session", constants.XMPP_SESSION_NS
        return if not session

        session = builder.session(@domain)

        sessionResponseHandler = (stanza) =>
            isSessionResponse = (stanza) ->
                r = stanza.is "iq"
                s = stanza.attrs.id is session.attrs.id
                t = stanza.attrs.type is "result"
                return r and s and t

            return if not isSessionResponse stanza

            @_transport.removeListener "stanza", sessionResponseHandler

            error = stanza.getChild "error"
            if error
                log "ERROR", logFormat, "bind: #{error}"
                @_terminate()
                return

            @_state = ConnectionStates.CONNECTED
            log "INFO", logFormat, "Session Estb"

        @_transport.on "stanza", sessionResponseHandler
        @_transport.send session.toString()

    _handleStreamFeatures: (stanza) =>
        return
        @_transport.removeListener "stanza", @_handleStreamFeatures
        if not stanza.is "features"
            log "ERROR", logFormat, "Invalid Stream Features received."
            @_terminate()
            return

        @_handleAuthentication stanza
        @_handleResourceBinding stanza
        @_handleSessionBinding stanza

    _terminate: () ->
        @_transport.terminate()
        log "INFO", "Session terminated"

    login: () ->
        @_transport.connect()

    logout: () ->
        logout this

    setPresence: () ->
        setPresence this

    sendMessage: (message) ->

    addContact: (jid) ->

    removeContact: (jid) ->


############ exports ############

exports.XmppClient = XmppClient




