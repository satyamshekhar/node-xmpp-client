exports.ConnectionStates =
    DISCONNECTED: 1
    CONNECTING: 2
    AUTH_MECH_SELECTED: 4
    AUTHENTICATING: 8
    AUTHENTICATED: 16
    BINDING_RESOURCE: 32
    ESTABLISHING_SESSION: 64
    CONNECTED: 128

exports.PresenceStates =
    AVAILABLE: 1
    BUSY: 2
    AWAY: 4
    OFFLINE: 8


exports.XMPP_NS = "jabber:client"
exports.XMPP_STREAM_NS = "http://etherx.jabber.org/streams"
exports.XMPP_SASL_NS = "urn:ietf:params:xml:ns:xmpp-sasl"
exports.XMPP_BIND_NS = "urn:ietf:params:xml:ns:xmpp-bind"
exports.XMPP_SESSION_NS = "urn:ietf:params:xml:ns:xmpp-session"