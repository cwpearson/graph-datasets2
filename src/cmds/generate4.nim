import random
import math
import strformat
import sequtils
import algorithm
import os
import bitops
import hashes

import ../logger
import ../init
import ../format
import ../edge_stream
import ../edge


proc getNnz(N: int64, g, c: float): int64 =
    assert c > 0
    var cnt: int64 = 0
    for i in 1 .. N:
        let raw = c * pow(float(i), -1.0 * g)
        try:
            cnt += int64(raw + 0.5) + 1
        except OverflowError:
            # this could also be an underflow, but raw should always be positive
            echo "overflow, return max"
            return high(int64)
    return cnt

proc nnzPerRow(N: int, g, c: float): seq[int] =
    result = newSeq[int](N)
    for i in 1 .. N:
        let raw = c * pow(float(i), -1.0 * g)
        result[i-1] = int(raw + 0.5) + 1

proc searchForC(N, nnz: int64, g: float): float =

    var ub = float(1e100)
    var lb = float(1e-100)
    var c = 1e10
    var prevC = 0.0

    while true:
        echo &"try {lb:e} {c:e} {ub:e}"
        let check = getNnz(N, g, c)

        if prevC == c:
            echo &"c unchanged"
            echo &"c yielded {check} nnzs"
            result = c
            break


        if check < nnz:
            # c is too small
            lb = c
            echo "^"
        elif check > nnz:
            # c was too big
            ub = c
            echo "v"
        else:
            echo &"c yielded {check} nnzs"
            result = c
            break
        prevC = c
        c = pow(ub * lb, 0.5)





when isMainModule:
    init()
    setLevel(lvlDebug)

    let targetNodes = 1_000_000_000
    let targetNnz = 8_000_000_000
    let g = 3.0

    let c = searchForC(targetNodes, targetNnz, g)
    let r = nnzPerRow(targetNodes, g, c)
    echo r[0..50], r[^51..^1]







