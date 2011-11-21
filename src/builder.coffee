ltx = require("ltx")
constants = require("./constants.coffee")

stanza = (name, attrs) ->
    new ltx.Element name, attrs

iq_pid = 1

exports.iq = iq = (attrs) ->
    attrs.id = "iq_id#{iq_pid++}" if attrs.type is "set"
    stanza "iq", attrs

exports.message = message =  (attrs) ->
    stanza "message", attrs

exports.presence = presence = (attrs) ->
    stanza "presence", attrs

exports.auth = auth = (attrs) ->
    attrs = attrs or { }
    attrs.xmlns = constants.XMPP_SASL_NS
    stanza "auth", attrs

exports.bind = (resource) ->
    attrs = attrs or { }
    attrs.xmlns = constants.XMPP_BIND_NS
    bind = stanza "bind", attrs

    iqBind = iq {type: "set"}
    iqBind.cnode bind

    if resource
        resourceNode = new ltx.Element "resource"
        resourceNode.t resource
        bind.cnode resourceNode

    return iqBind

exports.session = (domain) ->
    attrs =
        xmlns: constants.XMPP_SESSION_NS

    session = stanza "session", attrs

    iqSession = iq {
        type: "set"
        to: domain
    }

    iqSession.cnode session

    return iqSession
