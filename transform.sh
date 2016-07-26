#!/usr/bin/env bash
input=$1
if [ ! -f "$input" ]
then
	echo "ERROR: you must specify one FLAC file"
	echo ""
	echo "Usage:"
	echo "  $0 FLACfile"
	exit 1
fi

sample_rate=`metaflac --show-sample-rate "$1"`
bit_depth=`metaflac --show-bps "$1"`
downsample=""
lower_bit_depth=""
downsampled_name="$1.downsampled.flac"
sample_a_name="$1.sample_a.wav"
sample_b_name="$1.sample_b.wav"
dir="test_folder/"
output_dir="/output"
output_dir_complete="$dir/"$(dirname "$input")"$output_dir/"
lame_options=" --quiet -s 44.1 -B 96 --bitwidth 16 --noreplaygain -V7 "
echo Detected sample rate: $sample_rate
if [ "$sample_rate" -gt 44100 ]
then
	echo "Downsampling to 44.1kHz"
	downsample=" -r 44100 "
fi

echo Detected bit depth: $bit_depth
if [ "$bit_depth" -gt 16 ]
then
	echo "Converting bit depth to 16 bits/sample"
	lower_bit_depth=" -b 16 "
fi

echo "Creating test_folder"
mkdir -p "$dir/"$(dirname "$1")

if [[ (! -z "$downsample") || (! -z "$lower_bit_depth") ]]
then
	sox -q "$1" $downsample $lower_bit_depth "$dir/$downsampled_name"
	echo "Conversion done."
fi

# Convert flac to wav
echo "Decoding flac to wav"
flac -f -s -d "$dir/$downsampled_name" -o "$dir/$sample_a_name"
echo "Done decoding flac to wav"

# Convert wav to mp3
echo "Converting wav to mp3"
lame $lame_options "$dir/$sample_a_name" "$dir/$sample_b_name.mp3"
echo "Done converting wav to mp3"
# Convert mp3 to wav
echo "Converting mp3 to wav (to be unable to distinguish which file is which)"
lame --quiet --decode "$dir/$sample_b_name.mp3" "$dir/$sample_b_name"
echo "Done converting mp3 to wav"


if [ -d "$output_dir_complete" ]
then
	rm -Rf "$output_dir_complete"
fi

mkdir -p "$output_dir_complete" 

echo "Randomizing file names"

cp "$dir/$sample_a_name" "$output_dir_complete/$((RANDOM)).wav"
cp "$dir/$sample_b_name" "$output_dir_complete/$((RANDOM)).wav"
echo "Done."
