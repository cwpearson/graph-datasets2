import json
import nre
import strutils
import logger

import nethelper

const
    graphChallengeStaticRaw = staticRead("../static/graphchallengestatic.txt")
    matrixmarketRaw = staticRead("../static/matrixmarket.json")
    sparseChallenge2019Raw = staticRead("../static/sparsechallenge2019.json")
    suitesparseRaw = staticRead("../static/suitesparse.json")
    webDataCommonsRaw = staticRead("../static/webdatacommons.json")

proc makeJson(): JsonNode =
    result = newJObject()
    result{"matrixmarket"} = parseJson(matrixmarketRaw)
    result{"sparsechallenge2019"} = parseJson(sparseChallenge2019Raw)
    result{"suitesparse"} = parseJson(suitesparseRaw)
    result{"webdatacommons"} = parseJson(webDataCommonsRaw)

let allDatasets = makeJson()



type Resource* = object of RootObj
    description*: string
    size*: int
    url*: string

type Dataset* = object of RootObj
    description*: string
    name*: string
    resources*: seq[Resource]
    format*: string
    getter*: proc (output: string) {.closure.}

type Provider* = object of RootObj
    name*: string
    datasets*: seq[Dataset]
    bibtex*: string


proc initSparseChallenge*(json: JsonNode): Provider =
    result.name = "SparseChallenge"
    for dataset in json["datasets"]:
        var r: Resource
        r.url = dataset["url"].getStr()
        r.size = dataset["size"].getInt()

        var d: Dataset
        d.resources.add(r)
        d.name = dataset["name"].getStr()
        result.datasets.add(d)

    result.bibtex = json{"bibtex"}.getStr()

proc initGraphChallengeStatic*(raw: string): Provider =
    result.name = "GraphChallengeStatic"
    for raw_line in raw.splitLines():
        var line = raw_line.strip()
        let url = line
        let name = line[line.rfind("/")+1 .. ^1]
        let size = 0
        # determine format
        let format = if line.endsWith(".mmio"):
            "mtx"
        elif line.endsWith(".tsv"):
            "tsv"
        elif line.endsWith(".tsv.gz"):
            "tsv"
        else:
            raise newException(ValueError, "couldn't detect format for " & line)

        # determine description
        let description = if line.contains("_adj"):
            "adjacency"
        elif line.contains("_inc"):
            "incidence"
        else:
            ""

        proc download(): proc(path: string) =
            result = proc(path: string) =
                discard retrieve_url(url, path)


        proc downloadAndExtract(): proc(s: string) =
            result = proc(path: string) =
                discard retrieve_url(url, path)
                # do something to extract path

            # download strategy
        let getter = if line.endswith(".gz"):
            download()
        else:
            downloadAndExtract()

        let r = Resource(
            url: url,
            size: size,
        )
        let d = Dataset(
            description: description,
            name: name,
            format: format,
            resources: @[r],
            getter: getter,
        )
        result.datasets.add(d)


var allProviders*: seq[Provider]

allProviders.add(initSparseChallenge(allDatasets["sparsechallenge2019"]))
allProviders.add(initGraphChallengeStatic(graphChallengeStaticRaw))


iterator filterAll*(providerFilter: proc(p: Provider): bool,
        datasetFilter: proc(d: Dataset): bool): (Provider, Dataset) =
    for provider in allProviders:
        if not providerFilter(provider):
            continue
        for dataset in provider.datasets:
            if not datasetFilter(dataset):
                continue
            yield (provider, dataset)

proc `$`*(d: Dataset): string =
    d.name
