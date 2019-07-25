import json

const
    sparseChallenge2019Raw = staticRead("../static/sparsechallenge2019.json")
    graphChallengeStaticRaw = staticRead("../static/graphchallengestatic.json")
    webDataCommonsRaw = staticRead("../static/webdatacommons.json")

proc makeJson(): JsonNode =
    result = newJObject()
    result{"sparsechallenge2019"} = parseJson(sparseChallenge2019Raw)
    result{"graphchallengestatic"} = parseJson(graphChallengeStaticRaw)
    result{"webdatacommons"} = parseJson(webDataCommonsRaw)

let datasets = makeJson()

when isMainModule:
    echo datasets
    for key, node in pairs(datasets):
        echo key
