import json
import nre

const
    graphChallengeStaticRaw = staticRead("../static/graphchallengestatic.json")
    matrixmarketRaw = staticRead("../static/matrixmarket.json")
    sparseChallenge2019Raw = staticRead("../static/sparsechallenge2019.json")
    suitesparseRaw = staticRead("../static/suitesparse.json")
    webDataCommonsRaw = staticRead("../static/webdatacommons.json")

proc makeJson(): JsonNode =
    result = newJObject()
    result{"graphchallengestatic"} = parseJson(graphChallengeStaticRaw)
    result{"matrixmarket"} = parseJson(matrixmarketRaw)
    result{"sparsechallenge2019"} = parseJson(sparseChallenge2019Raw)
    result{"suitesparse"} = parseJson(suitesparseRaw)
    result{"webdatacommons"} = parseJson(webDataCommonsRaw)

let allDatasets = makeJson()



type Resource = object of RootObj
    description*: string
    size*: int
    url*: string
    format*: string

type Dataset = object of RootObj
    description*: string
    name*: string
    resources*: seq[Resource]

type Provider = object of RootObj
    name*: string
    datasets*: seq[Dataset]
    bibtex*: string

iterator items(providers: seq[Provider]): (Provider, Dataset, Resource) =
    discard

template nameIsLike *(a: untyped, pattern: string): bool =
    let regex = re(pattern)
    result = a.name.contains(regex)

proc nameLike*(t: Provider, pattern: string): seq[Dataset] =
    ## return datasets that match a name
    let regex = re(pattern)
    for dataset in t.datasets:
        if dataset.name.contains(regex):
            result.add(dataset)

proc formatLike*(t: Dataset, pattern: string): seq[Resource] =
    ## return resources that match a format
    let regex = re(pattern)
    for resource in t.resources:
        if ($resource.format).contains(regex):
            result.add(resource)


proc initSparseChallenge*(json: JsonNode): Provider =
    for dataset in json["datasets"]:
        var r: Resource
        r.url = dataset["url"].getStr()
        r.size = dataset["size"].getInt()
        var d: Dataset
        d.resources.add(r)
        d.name = dataset["name"].getStr()
        result.datasets.add(d)

    result.bibtex = json{"bibtex"}.getStr()

var allProviders*: seq[Provider]

allProviders.add(initSparseChallenge(allDatasets["sparsechallenge2019"]))




