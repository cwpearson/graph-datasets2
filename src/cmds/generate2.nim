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

const
    largePrime = 2'u64 ^ 64 - 59

{.push checks: off.}
proc murmur64A*(bytes: openArray[byte], seed: uint64 = 0): uint64 =
    ## https://github.com/aappleby/smhasher/blob/master/src/MurmurHash2.cpp
    let m = 0xc6a4a7935bd1e995'u64
    let r = 47

    var h = bitxor(seed, uint64(len(bytes)) * m)

    # echo &"h: {h}"

    var i = 0

    # do this 8 bytes at a time
    while i < (len(bytes) div 8) * 8:
        var k = cast[ptr uint64](unsafeAddr bytes[i])[]
        # echo &"i,k: {i},{k}"
        k *= m
        k = bitxor(k, k shr r)
        k *= m
        h = bitxor(h, k)
        h *= m
        i += 8
    # do this if there are any bytes remaining

    if i < len(bytes): # len = 15, i = 8
        var u = 0'u64
        let istart = i
        while i < len(bytes):
            let shamt = 8 * (i - istart)
            # echo &"i/tot, shamt: {i}/{len(bytes)}, {shamt}"
            u += uint64(bytes[i]) shl shamt
            i += 1
        # echo &"u: {u}"
        h = bitxor(h, u)
        h *= m

    h = bitxor(h, h shr r)
    h *= m
    h = bitxor(h, h shr r)

    result = h
    # echo &"{bytes},{seed} -> {result}"
{.pop.}

proc murmur64A*(x: int, seed: uint64 = 0): uint64 =
    let a = cast[array[sizeof(x), byte]](x)
    return murmur64A(a, seed)

proc murmur64A*(x: uint64, seed: uint64 = 0): uint64 =
    let a = cast[array[sizeof(x), byte]](x)
    return murmur64A(a, seed)

proc murmur64A*(x: uint32, seed: uint64 = 0): uint64 =
    let a = cast[array[sizeof(x), byte]](x)
    return murmur64A(a, seed)


type Bloom*[T] = object
    data: seq[uint64]
    k: int    # number of hash functions
    m: uint64 # number of bits
    p: uint64 # k / m

proc h1[T](b: Bloom[T], x: int): uint64 =
    result = murmur64A(x)

proc h2[T](b: Bloom[T], x: int): uint64 =
    result = murmur64A(x, largePrime)

proc hi[T](b: Bloom[T], x: int, i: int): uint64 =
    # compute the i'th hash of x
    # FIXME: this is sort of like kirsch-mitzenmacher optimization but not precisely
    # each hash should be in range 0..<p
    # total bits should be
    result = b.h1(x) + uint64(i) * b.h2(x)

proc initBloom*[T](p: float, n: uint64): Bloom[T] =
    ## construct a bloom filter with false positive rate `p` and expected number of entries `n`
    let m = -1.0 * float(n) * ln(p) / pow(ln(2.0), 2.0)
    result.m = ((uint64(m) div 64) + 1) * 64 # round up to multiple of 64
    assert result.m mod 64 == 0
    let k = -1.0 * log2(p)
    result.k = int(k)
    echo &"m = {m}, k = {k}"
    result.data = newSeq[uint64](result.m div 64)
    echo &"created"

proc numHashes*[T](b: Bloom[T]): int =
    b.k

proc numBits*[T](b: Bloom[T]): uint64 =
    b.m

proc setBit[T](b: var Bloom[T], i: uint64) =
    let fIdx = i div 64
    let bIdx = i mod 64
    let bits = bitor(b.data[fIdx], (1'u64 shl bIdx))
    b.data[fIdx] = bits

proc getBit[T](b: Bloom[T], i: uint64): bool =
    let fIdx = i div 64
    let bIdx = i mod 64
    result = bitand((b.data[fIdx] shr bIdx), 1'u64) != 0

proc add[T](b: var Bloom[T], val: T) =
    for i in 0..<b.k:
        let bi = b.hi(val, i) mod b.m
        b.setBit(bi)

proc contains[T](b: Bloom[T], val: T): bool =
    result = true
    for i in 0..<b.k:
        if not result:
            break
        let bi = b.hi(val, i) mod b.m
        result = result and b.getBit(bi)

#[
proc power(x0, x1, n: float64): float64 =
    ## selects a random number from the power-law distribution
    ## between x0 and x1 with power n
    ## http://mathworld.wolfram.com/RandomNumber.html
    let r = rand(0.0..1.0)
    let u = pow(x1, n+1)
    let l = pow(x0, n+1)
    let e = 1'f64/(n+1)
    # echo "l,u,r = ", l, ",", u, ",", r, ",", e
    result = pow(l + (u-l)*r, e)

proc power(x0, x1: int, n: float64): int =
    let raw = power(float64(x0), float64(x1) + 1, n)
    # echo "raw: ", raw
    result = int(raw)
    # echo "result: ", result

proc generate(numNodes, nnz: int, g: float, output: string, force: bool,
        seed: int64 = 0) =

    if fileExists(output) or dirExists(output):
        if not force:
            error(&"{output} already exists")
            quit(1)

    if seed != 0:
        info(&"seed: {seed}")
        randomize(seed)



    var nnzPerRow = newSeq[int](numNodes)
    var rowFilters = newSeq[Bloom[int]](numNodes)
    for i in 0..<numNodes:
        let r = power(0, numNodes-1, g)
        nnzPerRow[r] += 1

    os.close()
]#

when isMainModule:
    init()
    setLevel(lvlDebug)

    # discard murmur64A(0x01_00_00_00_00_00_00_00'u64)
    # discard murmur64A(1'u64)
    # discard murmur64A(1'u32)



    var b = initBloom[int](1e-7, uint64(1e8))

    var collisions = 0
    for i in 0..int(1e8):
        if i mod (1024 * 1024) == 0:
            echo "did ", i
        b.add(i)
        assert b.contains(i)
        if b.contains(i+1):
            echo &"false: {i}"





