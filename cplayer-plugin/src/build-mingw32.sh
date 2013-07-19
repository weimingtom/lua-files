set +e #errors break the entire script

windres -i npcplayer.rc -o npcplayer_rc.o

gcc npcplayer.c npcplayer_rc.o \
	-I../../csrc/lua -L../../bin -llua51 \
	-Wl,--kill-at -s -O3 -shared -o ../xpi/plugins/npcplayer.dll

rm -f npcplayer_rc.o

cd ../xpi
zip ../../../lua-files-xpi/npcplayer.xpi -q -r *
