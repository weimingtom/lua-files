git clone http://luajit.org/git/luajit-2.0.git
cd luajit-2.0
make
cd src
bindir=../../../../linux/bin
luadir_linux="$bindir/.."
cp -f libluajit.so "$bindir/libluajit-5.1.so.2"
cp -f luajit "$bindir/luajit-2.0"
cp -fR jit "$luadir_linux"
