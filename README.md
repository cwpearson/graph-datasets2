# graph-datasets2

master: [![Build Status](https://travis-ci.org/cwpearson/graph-datasets2.svg?branch=master)](https://travis-ci.org/cwpearson/graph-datasets2)

develop: [![Build Status](https://travis-ci.org/cwpearson/graph-datasets2.svg?branch=develop)](https://travis-ci.org/cwpearson/graph-datasets2)

Manage a variety of graph datasets

Download [the latest release](https://github.com/cwpearson/graph-datasets2/releases/latest) for your platform.

## Quick Start

## `graph_datasets --help`

See all the available commands

## `graph_datasets visualize`

Generate a BMP of the adjacency matrix sparsity pattern.
The row and column values in the matrix are added into pixel bins, which are then log-scaled before displaying.

* `graph_datasets visualize a.bel out.bmp`: Read the edge list in `a.bel` and generate a bitmap in `out.bmp`
* `graph_datasets visualize a.bel out.bmp --size 200 --no-log`: Don't apply log scaling, and make the output image 200x200.


## `graph_datasets download`

Download and extract datasets.

* `graph_datasets download neuron1024`: Download the sparse challenge 1024x1024 dataset.
* `graph_datasets download --list`: List all datasets.
* `graph_datasets download --list name`: Show datasets matching regex `name`.
* `graph_datasets download name --format tsv`: Download datasets matching regex `name` with format `tsv`.
* `graph_datasets download GraphChallengeStatic/graph500-scale18-ef16_inc/tsv`: Download this specific datasets


## `graph_datasets convert`

| format | type | signal | desc |
|-|-|-|-|
| GraphChallenge TSV | file | `.tsv` extension | [tsv](https://github.com/cwpearson/graph-datasets2#tsv) |
| BEL | file | `.bel` extension | [bel](https://github.com/cwpearson/graph-datasets2#bel)
| Matrix Market Coordinate | file | `.mtx` extension | [nist](https://math.nist.gov/MatrixMarket/formats.html)
| Binary Matrix Market Coordinate | file | `.bmtx` extension | [bmtx](https://github.com/cwpearson/graph-datasets2#bmtx)
| Twitter | file | `twitter_rv.zip` | [twitter](https://github.com/cwpearson/graph-datasets2#twitter)
| delimited | file | hint | [delimited](https://github.com/cwpearson/graph-datasets2#delimited)

* `graph_datasets convert a.tsv b.bmtx`: convert `a` from GraphChallenge tsv to binary matrix-market format.



## Building

Install the latest stable version of nim, then

```
nimble build
./graph_datasets --help
./tc --help
```

Optionally, `-d:webview` can be added to use the system webview instead of the default browser for the histogram plot.

On Ubuntu 18.04 you will need
```
sudo apt install libgtk-3-dev libwebkit2gtk-4.0-dev
```

`-d:release` can be added to improve performance.

## Complete

- [x] statistics of datasets
- [x] orient graphs
  - [x] lower triangular
  - [x] upper triangular
  - [x] degree-ordered
- [x] relabeling of vertex IDs
  - [x] graph compaction from Bisson & Fatica [Update on Static Graph Challenge on GPUs](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=8547514) (2018)
- [x] Convert between file formats
  - [x] graph challenge tab-separated values
    - [x] binary version
  - [x] matrix-market
    - [x] binary version of some entries and symmetries
- [x] provide binaries
  - [x] linux / amd64
  - [x] linux / ppc64le
  - [x] macOS / amd64
  - [x] windows / amd64
- [x] download datasets
  - [x] list datasets (`download --list`)
  - [x] filter by regex (`download "graph500*"`)
  - [x] filter by source (`download --provider GraphChallenge`)
  - [x] filter by format (`download --format mtx`)

## In Progress

- [ ] Download of datasets
    - [x] [Twitter](http://an.kaist.ac.kr/traces/WWW2010.html)
    - [x] [Static Graph Challenge](https://graphchallenge.mit.edu/data-sets)
    - [x] [Sparse Challenge](https://graphchallenge.mit.edu/data-sets)
    - [ ] [Matrix Market](https://math.nist.gov/MatrixMarket/browse.html)
    - [ ] [SuiteSparse](https://sparse.tamu.edu/)

## Not yet started
- [ ] Visualization of datasets
- [ ] Verification of datsets
- [ ] partitioning datasets

## Making a Release

1. Increment the package version in `graph_datasets2.nimble`.
2. Commit that change
3. Create a matching git tag
4. Push that tag
5. Go onto github and make the draft release a real release

*Copyright Carl Pearson 2019*

## Formats

### TSV

### BEL

### Twitter

### MTX

The [matrix-market coordinate format](https://math.nist.gov/MatrixMarket/formats.html)

### BMTX

A binary version of the [matrix-market](https://math.nist.gov/MatrixMarket/formats.html) coordinate general real format.

The first 24 bytes are `rows`, `cols`, `entries`, each as 8-byte integers.
The next bytes are a sequence of 24 byte fields, where each field is
* 8-byte integer `i` index
* 8-byte integer `j` index
* 8-byte IEEE 754 weight value

Note that like the matrix-market format, indices are 1-based instead of 0-based.

### Delimited

This is a generic name for any edge-list format where edges are separated by newlines, and fields within the edge are separated by some delimiter.

To convert this format to any other, use the convert command

```
./graph_datasets convert --input-kind delimited --src-pos 1 --dst-pos 0 --weight-pos 2 --delimiter '\t' edges.txt
```

This would read edges.txt as if it were an edge list that was line-delimited, where the field in each line was separate by a tab, and the dst node came first, followed by the source node, followed by the weight:

```
0    1  1.0
0    2 -1.0
```
edge 1->0 with weight 1.0 and edge 2->0 with weight -1.0.

The i and j indices do not have to be integers.
If they are not, this command will convert each unique field to a new integer ID in the emitted edge list.
The weight must be interpretable as a real number.
