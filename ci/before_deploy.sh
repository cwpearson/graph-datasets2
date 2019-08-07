set -eu
set -x

mkdir -p deploy

if [ -n "${CROSS_CPU+x}" ]; then
    zip -r deploy/graph_datasets-linux-$CROSS_CPU.zip graph_datasets
elif [ -n "${CROSS_OS+x}" ]; then
    if [ "$CROSS_OS" = "windows" ]; then
        mv graph_datasets graph_datasets.exe
        zip -r deploy/graph_datasets-$CROSS_OS-amd64 graph_datasets.exe
    else
        zip -r deploy/graph_datasets-$CROSS_OS-amd64 graph_datasets
    fi
elif [ "${CHANNEL}" = "stable" ]; then
    zip -r deploy/graph_datasets-$TRAVIS_OS_NAME-amd64 graph_datasets
fi