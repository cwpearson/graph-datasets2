set -eu
set -x

grep -E "version" graph_datasets2.nimble
grep -E "version" graph_datasets2.nimble | grep -Eo "[[:digit:]]+.[[:digit:]]+.[[:digit:]]+"
version=`grep -E "version" graph_datasets2.nimble | grep -Eo "[[:digit:]]+.[[:digit:]]+.[[:digit:]]+"`
sha=`git rev-parse HEAD`
verflags="-d:GdVerStr=$version -d:GdGitSha=$sha"
echo $version
echo $sha
echo $verflags

if [ -n "${CROSS_CPU+x}" ]; then
    nimble build --cpu:$CROSS_CPU --os:linux $verflags
else
    nimble build $verflags
fi