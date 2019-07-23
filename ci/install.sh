set -eu
set -x

curl https://nim-lang.org/choosenim/init.sh -sSf > init.sh
sh init.sh -y
nim c || true
echo "export PATH=~/.nimble/bin:$PATH" >> ~/.profile
choosenim $CHANNEL
TOOLCHAIN_DIR=`choosenim --noColor show | grep Path | cut -d " " -f 8`
echo "powerpc64el.linux.gcc.path = \"/usr/bin\"" >> $TOOLCHAIN_DIR/config/nim.cfg
echo "powerpc64el.linux.gcc.exe = \"powerpc64le-linux-gnu-gcc\"" >> $TOOLCHAIN_DIR/config/nim.cfg
echo "powerpc64el.linux.gcc.linkerexe = \"powerpc64le-linux-gnu-gcc\"" >> $TOOLCHAIN_DIR/config/nim.cfg
cat $TOOLCHAIN_DIR/config/nim.cfg