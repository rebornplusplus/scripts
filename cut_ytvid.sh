#!/bin/bash

# Dependencies:
# - [youtube-dl](https://youtube-dl.org/)
# - [ffmpeg](http://ffmpeg.org/)

usage() {
cat << EOF
Usage: `basename $0` [options..] URL

Download and cut youtube videos.

[options]
    -h
        Show this help information and exit.

    -s START_TIME
        Cut videos starting from START_TIME. If absent, cut from the start.

    -e END_TIME
        Cut videos till END_TIME. If absent, cut till the end.

    -o OUTPUT_PREFIX
        Specify the output file name, without extension.
EOF
}

fetch_filename() {
	filename=$(youtube-dl --get-filename -o "%(title)s" "$1")
	echo "$filename"
}

download_video() {
	youtube-dl -o "/tmp/%(title)s" "$1"
}

cut_video() {
	ffmpeg -i "$1" -ss "$2" -to "$3" "$4"
}

ST_TIME=""
EN_TIME=""
OUTPUT_PREFIX=""

while getopts ":hs:e:o:" opt; do
	case $opt in
		h)
			usage
			exit 0
			;;
		s)
			ST_TIME="$OPTARG"
			;;
		e)
			EN_TIME="$OPTARG"
			;;
		o)
			OUTPUT_PREFIX="$OPTARG"
			;;
		\?)
			echo "Error: Invalid option: -$OPTARG" >&2
			exit 1
			;;
		:)
			echo "Error: Option -$OPTARG requires an argument." >&2
			exit 1
			;;
	esac
done

if [ $(( $# - $OPTIND )) -lt 0 ]; then
    usage
    exit 1
fi

YT_URL="${@:$OPTIND:1}"

download_video "$YT_URL"

file=`find "/tmp/$(fetch_filename "$YT_URL")"*`
output_file=`basename "$file"`
if [[ $OUTPUT_PREFIX ]]; then
	extension="${file##*.}"
	output_file="${OUTPUT_PREFIX}.${extension}"
fi

if [[ $ST_TIME ]] && [[ $EN_TIME ]]; then
	ffmpeg -i "$file" -ss "$ST_TIME" -to "$EN_TIME" "$output_file"
elif [[ $ST_TIME ]]; then
	ffmpeg -i "$file" -ss "$ST_TIME" "$output_file"
elif [[ $EN_TIME ]]; then
	ffmpeg -i "$file" -to "$EN_TIME" "$output_file"
else
	mv "$file" "$output_file"
fi

if [ -f "$file" ]; then
	rm "$file"
fi
