constants = require("./constants.coffee")
PresenceStates = constants.PresenceStates

parsePresence = (presence) ->
    return null if not presence
    presence = presence.toLowerCase?()
    switch presence
        when "available" then return PresenceStates.AVAILABLE
        when "busy" then return PresenceStates.BUSY
        when "away" then return PresenceStates.AWAY
        when "offline" then return PresenceStates.OFFLINE
        else return null

############ Logging ############
logLevelMap =
    "DEBUG": 1
    "INFO": 2
    "WARN": 3
    "ERROR": 4
    "FATAL": 5
    "NONE": 6

logLevel = 1

getArguments = () ->
    return arguments

getNumberForLogLevel = (level) ->
    return logLevelMap[level]

setLogLevel = (level) ->
    logLevel = getNumberForLogLevel level

log = (args...) ->
    level = args.shift()
    logStr = args.shift()
    levelNo = getNumberForLogLevel level

    if levelNo >= logLevel
        logStr = "#{new Date()} #{level} #{logStr}"
        args.unshift logStr
        console.log.apply this, getArguments.apply(this, args)


############ jid ############
userFromJid = (jid) ->
    ind = jid.indexOf "@"
    return null if ind is -1
    return jid.substring 0, ind

resourceFromJid = (jid) ->
    ind = jid.indexOf "/"
    return null if ind is -1
    return jid.substring ind + 1

############ Misc ############
makexml = (name, attrs) ->
    xml = "<#{name}"
    for attr, value of attrs
        xml += " #{attr}=\"#{value}\""
    xml += ">"

############ exports ############

exports.log = log
exports.setLogLevel = setLogLevel
exports.makexml = makexml
exports.parsePresence = parsePresence
exports.userFromJid = userFromJid
exports.resourceFromJid = resourceFromJid