import hashes

type
    KeyValuePair[A, B] = tuple[key: A, value: B]
    Data[A, B] = seq[seq[KeyValuePair[A, B]]]
    Dict*[A, B] = object
        size: int
        data: Data[A, B]
        log2cap: int
        load: int

const
    growthFactor = 2
    loadLimit = 0.8 # https://en.wikipedia.org/wiki/Hash_table

proc enlarge[A, B](t: var Dict[A, B])

proc capacity[A, B](t: Dict[A, B]): int {.inline.} =
    result = (1 shl t.log2cap)

iterator pairs *[A, B](t: Dict[A, B]): (A, B) =
    for kvps in t.data:
        for kvp in kvps:
            let (k, v) = kvp
            yield (k, v)

iterator keys *[A, B](t: Dict[A, B]): A =
    for kvps in t.data:
        for (k, v) in kvps:
            yield k

proc len *[A, B](t: Dict[A, B]): int {.inline.} =
    result = t.size

proc rightSize *(desired: int): int =
    var cap = 0
    while (1 shl cap) < desired:
        cap += 1
    cap

proc initDict *[A, B](initial: int = 64): Dict[A, B] =
    let log2cap = rightSize(initial)
    newSeq(result.data, (1 shl log2cap))
    result.log2cap = log2cap

template get(d, key): untyped =
    var found = false
    let dataIdx = hash(key) and (capacity(d) - 1)
    for i, kv in t.data[dataIdx]:
        let (k, v) = kv
        if k == key:
            result = v
            found = true
    if not found:
        raise newException(KeyError, "Key not found")

proc `[]`*[A, B](t: Dict[A, B], key: A): B =
    get(t, key)

proc addToSlot[A, B](d: var Dict[A, B], index: int, key: A, val: B) {.inline.} =
    ## add key,val to slot `index`
    if len(d.data[index]) == 0:
        d.load += 1
    d.data[index].add((key, val))
    d.size += 1

template rawGet(d, key): untyped =
    hash(key) and (capacity(d) - 1)

proc hasKeyOrPut*[A, B](d: var Dict[A, B], key: A, val: B): bool =
    ## returns true if key is in the table, otherwise, inserts val
    enlarge(d)
    result = false
    let dataIdx = rawGet(d, key)
    for i, kv in d.data[dataIdx]:
        let (k, _) = kv
        if k == key:
            result = true
    if not result:
        addToSlot(d, dataIdx, key, val)


proc `[]=`*[A, B](t: var Dict[A, B], key: A, val: B) =
    enlarge(t)
    let dataIdx = rawGet(t, key)
    # find key if present
    var inserted = false
    for i, kv in t.data[dataIdx]:
        let (k, _) = kv
        if k == key:
            t.data[dataIdx][i] = (key, val)
            # echo "repl ", val, " in ", dataIdx
            inserted = true
            break
    # otherwise, append key to bin
    if not inserted:
        addToSlot(t, dataIdx, key, val)

proc hasKey*[A, B](t: var Dict[A, B], key: A): bool =
    let dataIdx = rawGet(t, key)
    # find key if present
    for i, kv in t.data[dataIdx]:
        let (k, _) = kv
        if k == key:
            return true
    return false


proc getOrDefault*[A, B](t: var Dict[A, B], key: A): B =
    let dataIdx = rawGet(t, key)
    # find key if present
    for i, kv in t.data[dataIdx]:
        let (k, v) = kv
        if k == key:
            result = v

proc getOrDefault*[A, B](t: var Dict[A, B], key: A, default: B): B =
    result = B
    let dataIdx = rawGet(t, key)
    # find key if present
    for i, kv in t.data[dataIdx]:
        let (k, v) = kv
        if k == key:
            result = v

proc enlarge[A, B](t: var Dict[A, B]) =
    if float(t.load) / float(t.capacity) > loadLimit:
        # echo "enlarging ", t.capacity, " -> ", t.capacity * growthFactor
        var n = initDict[A, B](t.capacity * growthFactor)

        # insert into new table
        for k, v in t:
            n[k] = v

        swap(n, t)

when isMainModule:
    import system
    import times
    import tables
    var d = initDict[int, int]()
    var t = initTable[int, int]()
    echo getTotalMem() / 1024 / 1024, " MB"
    let upper = 1_000_00
    var start = cpuTime()
    for i in 0..upper:
        d[i] = i
        d[i + 2*upper] = i
    echo cpuTime() - start
    echo getTotalMem() / 1024 / 1024, " MB"
    for i in 0..upper:
        t[i] = i
        t[i + 2*upper] = i
    echo cpuTime() - start
    echo getTotalMem() / 1024 / 1024, " MB"
    start = cpuTime()
    for i in 0..upper:
        assert d.hasKey(i)
    echo cpuTime() - start
    start = cpuTime()
    for i in 0..upper:
        assert t.hasKey(i)
    echo cpuTime() - start

