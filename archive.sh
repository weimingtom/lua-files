# create zip files andd upload them to google code.

P=lua-files
DATE=`date +%F`

(cd .. || exit 1

rm $P/*.zip

zip -9 -r $P/$P-$DATE.zip $P \
	-x $P/upload.py \
	-x $P/.\* \
	-x $P/_attic/\* \
	-x $P/media/\* \
	-x $P/wiki/\* \
	-x $P/bin/plugins/\* \
	-x $P/bin/libvlc\*.dll

zip -r $P/$P-media-$DATE.zip $P/media \
	-x $P/media/.\*

zip -r $P/$P-vlc-$DATE.zip $P/bin/libvlc*.dll $P/bin/plugins \
	-x $P/bin/plugins/plugins.dat

)

for f in $P $P-media $P-vlc
do
	echo "uploading $f..."
	#python -uB upload.py -s $f -p $P -ucosmin.apreutesei -wxxx $f-$DATE.zip
done
