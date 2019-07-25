set -eu
set -x

mkdir -p deploy

if [ -n "${CROSS_CPU+x}" ]; then
    mv graph_datasets deploy/graph_datasets-linux-$CROSS_CPU
elif [ -n "${CROSS_OS+x}" ]; then
    if [ "$CROSS_OS" = "windows" ]; then
        mv graph_datasets deploy/graph_datasets-$CROSS_OS-amd64.exe
    else
        mv graph_datasets deploy/graph_datasets-$CROSS_OS-amd64
    fi
elif [ "${CHANNEL}" = "stable" ]; then
    mv graph_datasets deploy/graph_datasets-$TRAVIS_OS_NAME-amd64
fi