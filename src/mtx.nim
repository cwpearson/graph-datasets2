# Reader for the matrix market exchange coodinate format

import strutils
import strformat
import streams
import strscans
import complex

import edge
import edge_stream
import logger
import version

type EntryKind* = enum
    ekReal = "real",
    ekComplex = "complex",
    ekInteger = "integer",
    ekPattern = "pattern"

type SymmetryKind* = enum
    skGeneral = "general",
    skSymmetric = "symmetric",
    skSkewSymmetric = "skew-symmetric",
    skHermitian = "hermitian"

type Entry = object
    row: int
    col: int
    case kind: EntryKind
    of ekReal: fVal: float
    of ekComplex: cVal: Complex[float]
    of ekInteger: iVal: int
    else: discard

type
    MtxStream* = ref object of EdgeStream
        rows*: int
        cols*: int
        entries*: int
        entries_pos: int
        num_edges_written: int
        entryKind*: EntryKind
        symmetryKind*: SymmetryKind

proc readEntry(s: MtxStream, entry: var Entry): bool =
    var
        line: string
    result = s.stream.readLine(line)
    if result:
        var
            row, col: int
        case s.entryKind
        of ekReal:
            var val: float
            if scanf(line, "$s$i$s$i$s$f$s$.", row, col, val):
                entry = Entry(row: row, col: col, kind: ekReal, fVal: val)
            elif not s.atEnd():
                error("error parsing line ", line)
                quit(1)
            else:
                result = false
        of ekInteger:
            var val: int
            if scanf(line, "$s$i$s$i$s$i$s$.", row, col, val):
                entry = Entry(row: row, col: col, kind: ekInteger, iVal: val)
            elif not s.atEnd():
                error("error parsing line ", line)
                quit(1)
            else:
                result = false
        of ekPattern:
            if scanf(line, "$s$i$s$i$s$.", row, col):
                entry = Entry(row: row, col: col, kind: ekPattern)
            elif not s.atEnd():
                error("error parsing line ", line)
                quit(1)
            else:
                result = false
        of ekComplex:
            var val: Complex[float]
            if scanf(line, "$s$i$s$i$s$f$s$f$s$.", row, col, val.re, val.im):
                entry = Entry(row: row, col: col, kind: ekComplex, cVal: val)
            elif not s.atEnd():
                error("error parsing line ", line)
                quit(1)
            else:
                result = false


method readEdge *(s: MtxStream, edge: var Edge): bool =
    # start reading after the comments/header
    let data_pos = s.entries_pos
    if s.getPosition() < data_pos:
        debug(&"set position past header: {datapos}")
        s.setPosition(datapos)

    var entry: Entry
    result = s.readEntry(entry)
    if result:
        let
            src = entry.row
            dst = entry.col
        var weight: float
        case s.entryKind:
        of ekReal:
            weight = entry.fVal
        of ekInteger:
            weight = float(entry.iVal)
        of ekPattern, ekComplex:
            weight = 1.0
        edge = Edge(src: src - 1, dst: dst - 1, weight: weight)




method writeEdge*(s: MtxStream, edge: Edge) =
    let
        src = edge.src + 1
        dst = edge.dst + 1
        weight = edge.weight
    assert src <= s.rows, &"edge with row {src} is outside matrix {s.rows}"
    assert dst <= s.cols, &"edge with col {dst} is outside matrix {s.cols}"
    assert s.num_edges_written <= s.entries, &"wrote more edges {s.num_edges_written} than expected {s.entries}"
    s.stream.writeLine($src & "\t" & $dst & "\t" & $weight)
    s.num_edges_written += 1


proc readBanner *(s: MtxStream) =
    ## expect to read a line like `%%MatrixMarket matrix coordinate real general` from the first line of the file
    let curPos = s.getPosition()

    s.setPosition(0)
    var line: string
    if not s.stream.readLine(line):
        error("unable to read header line")
        quit(1)
    let fields = line.splitWhitespace()
    assert fields[0] == "%%MatrixMarket"
    assert fields[1] == "matrix"
    assert fields[2] == "coordinate"
    case fields[3]
    of $ekReal: s.entryKind = ekReal
    of $ekComplex: s.entryKind = ekComplex
    of $ekInteger: s.entryKind = ekInteger
    of $ekPattern: s.entryKind = ekPattern
    else:
        quit(1)

    case fields[4]
    of "general": s.symmetryKind = skGeneral
    of "symmetric": s.symmetryKind = skSymmetric
    of "skew-symmetric": s.symmetryKind = skSkewSymmetric
    of "hermitian": s.symmetryKind = skHermitian
    else:
        quit(1)

    info(&"read mtx banner: {s.entryKind} {s.symmetryKind}")

    s.setPosition(curPos)

proc readSize(s: MtxStream) =
    var line: string
    if not s.stream.readLine(line):
        error(&"couldn't readSize")
        quit(1)

    if not scanf(line, "$s$i$s$i$s$i$s$.", s.rows, s.cols, s.entries):
        error(&"couldn't get mtx size from : {line}")
        quit(1)
    info(&"mtx size was {s.rows} {s.cols} {s.entries}")

proc skipComments(s: MtxStream) =
    var line: string
    while s.stream.peekLine(line):
        if line.startsWith("%"):
            discard s.stream.readLine(line)
            debug(&"skip comment line {line}")
        else:
            break


proc writeBanner*(s: MtxStream, ek: EntryKind, sk: SymmetryKind) =
    if 0 != s.getPosition():
        error(&"must write banner at position 0")
        quit(1)
    s.stream.writeLine("%%MatrixMarket matrix coordinate " & $ek & " " & $sk)


proc newMtxStream(stream: Stream): MtxStream =
    new(result)
    result.stream = stream


proc newMtxWriter *(stream: Stream, rows, cols, entries: int): MtxStream =
    result = newMtxStream(stream)
    result.rows = rows
    result.cols = cols
    result.entries = entries
    result.stream.writeLine("%%MatrixMarket matrix coordinate real general")
    result.stream.writeLine(&"%generated by: {version.GdUrl}")
    result.stream.writeLine(&"%version:      {version.GdVerStr}")
    result.stream.writeLine(&"%git sha:      {version.GdGitSha}")
    result.stream.writeLine(&"{result.rows} {result.cols} {result.entries}")
    result.num_edges_written = 0


proc openMtxWriter *(path: string, rows, cols, entries: int): MtxStream =
    var stream = openFileStream(path, fmWrite)
    result = newMtxWriter(stream, rows, cols, entries)



proc newMtxReader *(stream: Stream): MtxStream =
    result = newMtxStream(stream)
    result.readBanner()
    result.skipComments()
    result.readSize()
    result.entries_pos = result.stream.getPosition()

proc openMtxReader *(path: string): MtxStream =
    var stream = openFileStream(path, fmRead)
    result = newMtxReader(stream)

when isMainModule:
    import init
    init()
    setLevel(lvlDebug)
    let contents = """%%MatrixMarket matrix coordinate real general
%test comment
%
%another comment
1 2 3
1   1   1.0    
1   2   2.0
    """
    var stream = newStringStream(contents)
    var reader = newMtxReader(stream)
    for edge in reader.edges():
        echo edge

    var ostream = newStringStream()
    var writer = newMtxWriter(ostream, 1, 2, 2)
    reader.setPosition(0)
    for edge in reader.edges():
        echo edge
        writer.writeEdge(edge)

    echo ostream.data
