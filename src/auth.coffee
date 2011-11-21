ltx = require("ltx")
util = require("util")
clientUtils = require("./client-utils.coffee")
EventEmitter = require("events").EventEmitter

constants = require("./constants.coffee")

plainHandler = (client) ->
    emitter = new EventEmitter()

    attrs =
        xmlns: constants.XMPP_SASL_NS
        mechanism: "PLAIN"

    auth = new ltx.Element "auth", attrs

    user = clientUtils.userFromJid client.jid
    payload = new Buffer("\u0000#{user}\u0000#{client.password}").toString("base64")
    auth.t payload

    responseHandler = (stanza) ->
        client._transport.removeListener "stanza", responseHandler
        if stanza.is "success", constants.XMPP_SASL_NS then emitter.emit "success"
        else emitter.emit "failure"

    client._transport.on "stanza", responseHandler
    client._transport.send auth

    return emitter


plainPWHandler = (client, token) ->
    emitter = new EventEmitter()

    attrs =
        xmlns: constants.XMPP_SASL_NS
        mechanism: "PLAIN-PW-TOKEN"

    token = token or "RandomMetaToken"

    auth = new ltx.Element "auth", attrs
    user = clientUtils.userFromJid client.jid
    payload = new Buffer("\u0000#{user}\u0000#{client.password}\u0000#{token}").toString("base64")
    auth.t payload

    responseHandler = (stanza) ->
        client._transport.removeListener "stanza", responseHandler
        if stanza.is "success", constants.XMPP_SASL_NS
            token = stanza.getChild("pw-token")?.getText()
            emitter.emit "success", token
        else emitter.emit "failure"

    client._transport.on "stanza", responseHandler
    client._transport.send auth

    return emitter


authenticationMechanisms =
    "PLAIN-PW-TOKEN": plainPWHandler
    "PLAIN": plainHandler
    "DIGEST-MD5": null

authenticate = (client, mechanisms) ->
    supportedMechanisms = { }
    mechanisms = mechanisms.getChildren "mechanism"

    for mechanism in mechanisms
        mechanism = mechanism.getText()
        supportedMechanisms[mechanism] = true

    for mech, handler of authenticationMechanisms
        if supportedMechanisms[mech]
            return handler client

    return false

############ exports ############
exports.authenticate = authenticate