# graph-datasets2

master: [![Build Status](https://travis-ci.org/cwpearson/graph-datasets2.svg?branch=master)](https://travis-ci.org/cwpearson/graph-datasets2)

develop: [![Build Status](https://travis-ci.org/cwpearson/graph-datasets2.svg?branch=develop)](https://travis-ci.org/cwpearson/graph-datasets2)

Manage a variety of graph datasets

Visit [releases](https://github.com/cwpearson/graph-datasets2/releases) to download the latest version for linux (amd64/ppc64le) and macOS (amd64).

## Features

* Conversion between multiple formats
* Resumable downloads (for large datasets)
* Some statistics on a variety of datasets

## Building

Install the latest stable version of nim, then

```
nimble build -d:release
./graph_datasets --help
./tc --help
```

## Complete

- [x] statistics of datasets
- [x] orient graphs
  - [x] lower triangular
  - [x] upper triangular
  - [x] degree-ordered
- [x] relabeling of vertex IDs
  - [x] graph compaction from Bisson & Fatica [Update on Static Graph Challenge on GPUs](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=8547514) (2018)
- [x] File formats
  - [x] graph challenge tab-separated values
    - [x] direct version
  - [x] matrix-market coordinate real
    - [x] binary version

## In Progress

- [ ] Download of datasets
    - [x] Twitter (`http://an.kaist.ac.kr/traces/WWW2010.html`)
    - [x] a few graph challenge datasets 
    - [ ] listing / filtering datasets
      - [x] preliminary filtering by name
      - [ ] filter by source (`--source graphchallenge`)
      - [ ] filter name by regex (`--re "graph500*"`)
    - [ ] `--continue` flag to resume a download
- [ ] provide binaries
  - [x] linux / amd64
  - [x] linux / ppc64le
  - [x] macOS / amd64
  - [ ] windows / amd64

## Not yet started
- [ ] Visualization of datasets
- [ ] Verification of datsets
- [ ] partitioning datasets


*Copyright Carl Pearson 2019*