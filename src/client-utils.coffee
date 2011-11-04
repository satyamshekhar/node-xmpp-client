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