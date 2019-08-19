import heapqueue
import streams
import deques
import strformat
import os

import tempdir

import ../logger
import ../edge_stream
import ../format
import ../tsv
import ../edge
import convert

const runLength = 1024 * 1024 * 1024

type Edge =
    tuple[src, dst: int, val: float]

proc initEdge(edge: edge.Edge): Edge {.inline.} =
    result.src = edge.src
    result.dst = edge.dst
    result.val = edge.weight

proc initEdge(e: Edge): edge.Edge {.inline.} =
    result.src = e.src
    result.dst = e.dst
    result.weight = e.val

proc bySrc(a, b: Edge): bool =
    if a.src == b.src:
        if a.dst == b.dst:
            return a.val < b.val
        return a.dst < b.dst
    return a.src < b.src

proc byDst(a, b: Edge): bool =
    if a.dst == b.dst:
        if a.src == b.src:
            return a.val < b.val
        return a.src < b.src
    return a.dst < b.dst

proc `<`(a, b: Edge): bool =
    result = byDst(a, b)


type SortKind = enum
    skSrc = "src"
    skDst = "dst"

proc sort (src: string, dst: string, force: bool, sortKind: SortKind) =
    var cmp: proc(a, b: Edge): bool = nil
    case sortKind:
    of skSrc:
        cmp = bySrc
    of skDst:
        cmp = byDst

    if fileExists(dst) or dirExists(dst):
        error(&"{dst} already exists")
        quit(1)

    if src == dst:
        error(&"input and output cannot be the same: {src}")
        quit(1)


    withTempDirectory(tmpDir, "graph_datasets"):
        info(&"using temp dir {tmpDir}")

        var sorter = initHeapQueue[Edge]()

        info(&"open {src}")
        var inf = guessEdgeStreamReader(src)

        var runFiles = initDeque[string]()
        var runCount = 0

        proc getTempTsvFile(): string =
            result = tmpDir / $runCount & ".tsv"
            runCount += 1

        proc dumpRuns(q: var HeapQueue[Edge]): string =
            let name = getTempTsvFile()
            var outf = openTsvStream(name, fmWrite)
            info(&"create {name}")

            # write out sorted lines
            while len(sorter) > 0:
                outf.writeEdge(initEdge(sorter.pop()))
            outf.close()
            result = name

        for edge in inf.edges():
            if len(sorter) >= runLength:
                let runName = dumpRuns(sorter)
                runFiles.addFirst(runName)

            sorter.push(initEdge(edge))
        inf.close()

        # dump any unwritten lines
        if len(sorter) > 0:
            let runName = dumpRuns(sorter)
            runFiles.addFirst(runName)

        # phase 2: merge all temp files
        while len(runFiles) >= 2:
            notice(&"merge runs: {len(runFiles)} remaining")
            let name1 = runFiles.popLast()
            let name2 = runFiles.popLast()
            var name3 = getTempTsvFile()

            echo &"merge {name1} & {name2} -> {name3}"

            var f1 = guessEdgeStreamReader(name1)
            var f2 = guessEdgeStreamReader(name2)
            var f3 = openTsvStream(name3, fmWrite)

            var edge1, edge2: edge.Edge
            var edge1good = f1.readEdge(edge1)
            var edge2good = f2.readEdge(edge2)
            while true:

                # no new data in either file
                if (not edge1good) and (not edge2good):
                    break
                # only file 1 has data
                elif edge1good and not edge2good:
                    f3.writeEdge(edge1)
                    edge1good = f1.readEdge(edge1)
                # onle file2 has data
                elif edge2good and not edge1good:
                    f3.writeEdge(edge2)
                    edge2good = f2.readEdge(edge2)
                # both lines are good, write whichever line is first
                else:
                    if initEdge(edge1) < initEdge(edge2):
                        f3.writeEdge(edge1)
                        edge1good = f1.readEdge(edge1)
                    elif initEdge(edge2) < initEdge(edge1):
                        f3.writeEdge(edge2)
                        edge2good = f2.readEdge(edge2)
                    else:
                        f3.writeEdge(edge1)
                        edge1good = f1.readEdge(edge1)
                        f3.writeEdge(edge2)
                        edge2good = f2.readEdge(edge2)

            f1.close()
            f2.close()
            f3.close()
            runFiles.addFirst(name3)

        # phase 3: create output file
        assert len(runFiles) == 1
        discard convert(runFiles.popLast(), dst, force)


proc doSort *[T](opts: T) =
    var sortKind = case opts.kind:
    of "src": skSrc
    of "dst": skDst
    else:
        error(&"unexpected sortKind {opts.kind}")
        quit(1)
    sort(src = opts.input, dst = opts.output, force = opts.force,
            sortKind = sortKind)

when isMainModule:
    import ../init
    init()
    setLevel(lvlDebug)
    sort("/Users/pearson/graph/as20000102_adj.tsv", "blah.tsv")
