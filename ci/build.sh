set -eu
set -x

if [ -n "${CROSS_CPU+x}" ]; then
    nimble build --cpu:$CROSS_CPU --os:linux -d:release
elif [ -n "${CROSS_OS+x}" ]; then
    if [ "$CROSS_OS" = "windows" ]; then
        nimble build -d:mingw --cpu:amd64 -d:release
    fi
else
    nimble build -d:release
fi