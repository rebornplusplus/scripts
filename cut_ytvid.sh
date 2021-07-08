# Dependencies:
# 	[youtube-dl](https://youtube-dl.org/)
#	[ffmpeg](http://ffmpeg.org/)

if [ "$#" -lt 4 ]; then
	echo "Usage:"
	echo "	./SCRIPTNAME YT_URL ST_TIME EN_TIME FILENAME_WITHOUT_EXTENSION"
	echo "	ST_TIME and EN_TIME in hh:mm:ss format"
fi

YT_URL=$1
ST_TIME=$2
EN_TIME=$3
FILENAME_WITHOUT_EXTENSION=$4
TEMPLATE=".ac7e1adbc669c240a74d088875e"

youtube-dl "$YT_URL" -o $TEMPLATE

DOWNLOADED_FILE=`find $TEMPLATE*`
EXT=${DOWNLOADED_FILE##*.}
FULLFILENAME=$FILENAME_WITHOUT_EXTENSION"."$EXT
echo $DOWNLOADED_FILE $FULLFILENAME $EXT

# Slower, but A/V sync
# ffmpeg -i $DOWNLOADED_FILE -ss $ST_TIME -to $EN_TIME $FULLFILENAME
# Faster, but A/V might be slightly out of sync
ffmpeg -i $DOWNLOADED_FILE -ss $ST_TIME -to $EN_TIME -c copy $FULLFILENAME
rm $DOWNLOADED_FILE
