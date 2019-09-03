import json
import nre
import strutils
import os
import strformat
import uri

import untar

import logger
import nethelper
import init
import gzhelper
import pathhelper

const
    graphChallengeStaticRaw = staticRead("../static/graphchallengestatic.txt")
    matrixmarketRaw = staticRead("../static/matrixmarket.json")
    sparseChallenge2019Raw = staticRead("../static/sparsechallenge2019.json")
    suitesparseRaw = staticRead("../static/suitesparse.json")
    webDataCommonsRaw = staticRead("../static/webdatacommons.json")

type
    Dataset* = ref object of RootObj
        description*: string
        name*: string
        format*: string
        reservedDirs*: seq[string]
        reservedFiles*: seq[string]
        provider*: string
        bibtex*: string
    GraphChallengeStaticDataset* = ref object of Dataset
        gzName*: string
        extractName*: string
        size*: int
        url*: string
    SparseChallengeDataset* = ref object of Dataset
        layers_size*: int
        layers_url*: string
        cat120_url*: string
        cat480_url*: string
        cat1920_url*: string
        images_url*: string
        images_size*: int


proc newSparseChallengeDataset(): SparseChallengeDataset =
    new(result)

method verifyDownload*(d: Dataset, dir: string): bool {.base.} =
    # override this base method
    false

method download*(d: Dataset, dir: string) {.base.} =
    # override this base method
    quit "to override!"

method verify*(d: Dataset, dir: string): bool {.base.} =
    # override this base method
    false

method extract*(d: Dataset, dir: string) {.base.} =
    # override this base method
    quit "to override!"

## Static Graph Challenge methods
##
##


method verifyDownload*(d: GraphChallengeStaticDataset, dir: string): bool =
    ## verify that the dataset exists in dir
    let url = d.url
    let dlName = getUrlTail(url)
    let dlPath = dir / dlName
    if existsFile(dlPath):
        let url = d.url
        let localSz = getFileSize(dlPath)
        debug(&"{dlPath} size is {localSz}")
        let remoteSz = getUrlSize(url)
        debug(&"{url} size is {remoteSz}")
        if localSz != remoteSz:
            return false
        else:
            return true
    return false

method download*(d: GraphChallengeStaticDataset, dir: string) =
    ## download the dataset into directory dir
    let url = d.url
    if d.gzName != "":
        retrieveUrl(url, dir / d.gzName)
    else:
        retrieveUrl(url, dir / d.extractName)

method verify*(d: GraphChallengeStaticDataset, dir: string): bool =
    ## verify that dir contains the dataset
    let gzPath = dir / d.gzName
    let extractPath = dir / d.extractName
    if fileExists(gzPath) and fileExists(extractPath):
        if getFileSize(extractPath) mod (1024 * 1024 * 1024 * 4) ==
                getExtractedSize(gzPath):
            return true
    return false

method extract*(d: GraphChallengeStaticDataset, dir: string) =
    ## extract a previously-downloaded dataset, if necessary
    if d.gzName != "":
        notice(&"extracting {dir / d.gzName}")
        extractGz(dir / d.gzName)
    else:
        debug(&"skipping extract (not compressed)")

## Sparse Challenge Methods
##
##

method download*(d: SparseChallengeDataset, dir: string) =
    ## download the dataset into directory dir



    proc doit(url: string) =
        let
            src = url
            dst = dir / getUrlTail(url)
        notice(&"download {src} to {dst}")
        retrieveUrl(src, dst)
    doit(d.layers_url)
    doit(d.cat120_url)
    doit(d.cat480_url)
    doit(d.cat1920_url)
    doit(d.images_url)

method extract*(d: SparseChallengeDataset, dir: string) =
    ## extract a previously-downloaded dataset, if necessary

    notice(&"extracting {dir / getUrlTail(d.layers_url)}")
    var file = newTarFile(dir / getUrlTail(d.layers_url))
    file.extract(dir)
    file.close()

    notice(&"extracting {dir / getUrlTail(d.images_url)}")
    extractGz(dir / getUrlTail(d.images_url))


proc initDataset*(): Dataset =
    result

proc initSparseChallenge*(): seq[Dataset] =

    let json = parseJson(sparseChallenge2019Raw)
    let bibtex = json{"bibtex"}.getStr()
    for dataset in json["datasets"]:
        # echo dataset
        var d = newSparseChallengeDataset()
        d.provider = "SparseChallenge"
        d.layers_url = dataset["layers_url"].getStr()
        d.layers_size = dataset["layers_size"].getInt()
        d.cat120_url = dataset["cat120_url"].getStr()
        d.cat480_url = dataset["cat480_url"].getStr()
        d.cat1920_url = dataset["cat1920_url"].getStr()
        d.images_url = dataset["images_url"].getStr()
        d.name = dataset["name"].getStr()
        d.bibtex = bibtex
        result.add(d)


proc initGraphChallengeStatic*(): seq[Dataset] =
    let raw = graphChallengeStaticRaw
    for raw_line in raw.splitLines():
        var line = raw_line.strip()
        let url = line
        let tail = getUrlTail(url)
        let name = fullSplitFile(tail).name
        var gzName, extractName: string
        if tail.endsWith(".gz"):
            gzName = tail
            extractName = pathWithoutGz(tail)
        else:
            extractName = tail
        let size = 0
        # determine format
        let format = if line.endsWith(".mmio") or line.endsWith(".mmio.gz"):
            "mtx"
        elif line.endsWith(".tsv") or line.endsWith(".tsv.gz"):
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

        # determine reserved files
        var reservedFiles = @[getUrlTail(url)]
        if url.endsWith(".gz"):
            reservedFiles.add(pathWithoutGz(getUrlTail(url)))

        let d = GraphChallengeStaticDataset(
            provider: "GraphChallengeStatic",
            reservedFiles: reservedFiles,
            url: url,
            size: size,
            description: description,
            name: name,
            format: format,
            gzName: gzName,
            extractName: extractName,
        )
        result.add(d)


var allDatasets*: seq[Dataset]

proc initDatasets*() =
    for d in initSparseChallenge():
        allDatasets.add(d)
    for d in initGraphChallengeStatic():
        allDatasets.add(d)


proc `$`*(d: Dataset): string =
    result = d.provider
    result &= "/" & d.name
    result &= "/" & d.format

proc nameRegexMatcher*(regex: string): proc(d: Dataset): bool =
    result = proc (d: Dataset): bool =
        return ($d).contains(re(regex))

proc providerExactMatcher*(provider: string): proc(d: Dataset): bool =
    result = proc (d: Dataset): bool =
        return d.provider == provider

proc formatExactMatcher*(format: string): proc(d: Dataset): bool =
    result = proc (d: Dataset): bool =
        return d.format == format

atInit(initDatasets)
