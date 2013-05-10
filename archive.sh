# create zip files and upload them to google code.
# be sure to put your password in password.txt first.

# NOTE: upload.py doesn't support overwriting existing files,
# so be sure to delete the old files from google code first.

P=lua-files
DATE=-latest
#DATE=`date +%F`

archive() {
	local module=$1; shift
	local zipfile=$P/$module$DATE.zip
	echo "archiving $module..."
	(
	cd .. || exit 1
	rm -f $zipfile
	zip -9 -r $zipfile "$@"
	)
	upload $module
}

upload() {
	local module=$1
	echo "uploading $module..."
	python -uB upload.py -s $module -p $P -ucosmin.apreutesei -w$(cat password.txt) $module$DATE.zip
}

archive_sources() {
	archive $P $P \
		-x $P/upload.py \
		-x $P/.\* \
		-x $P/_attic/\* \
		-x $P/media/\* \
		-x $P/wiki/\* \
		-x $P/bin/plugins/\* \
		-x $P/bin/libvlc\*.dll
}

archive_media() {
	archive $P-media $P/media \
		-x $P/media/.\*
}

archive_sources
#archive_media

