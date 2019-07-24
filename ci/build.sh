set -eu
set -x

version=`grep -E "version" graph_datasets2.nimble | grep -Eo "[[:digit:]]+.[[:digit:]]+.[[:digit:]]+"`
sha=`git rev-parse HEAD`
verflags="-d:GdVerStr=$version -d:GdGitSha=$sha"
echo $version
echo $sha
echo $verflags

if [ -n "${CROSS_CPU+x}" ]; then
    nimble build --cpu:$CROSS_CPU --os:linux $verflags
elif [ -n "${CROSS_OS+x}" ]; then
    if [ "$CROSS_OS" = "windows" ]; then
        nimble build -d:mingw --cpu:amd64
    fi
else
    nimble build $verflags
fi