import nre
import strutils
import strformat

proc preprocess(s: string): string =
    ## Process string by
    ## -- removing all but letters and numbers
    ## -- trim whitespace
    ## -- force to lower case

    result = s.strip()
    result = result.toLowerAscii()

proc ratio*(s1, s2: string): float =
    ## compute ratio using levenshtein edit distance
    let p1 = preprocess(s1)
    let p2 = preprocess(s2)
    let max_distance = max(len(p1), len(p2))
    result = 100 * (max_distance - strutils.editDistance(p1, p2)) / max_distance

when isMainModule:
    echo "a, a: ", ratio("a", "a")
    echo "a, b: ", ratio("a", "b")
    echo "aa, ab: ", ratio("aa", "ab")
    echo "Aa, ab: ", ratio("Aa", "ab")
    echo "aa, bb: ", ratio("aa", "bb")
    echo "aaa, aab: ", ratio("aaa", "aab")
    echo "aaa , aab: ", ratio("aaa ", "aab")

