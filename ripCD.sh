#!/bin/bash

TEMPDIR="/media/smallarray/tmp/music"

##prerequisites: apt-get install cddb cdparanoia cd-discid
pushd $(pwd);
cd $TEMPDIR;

trackNames=();
artistName="";
albumName="";

#Just take the first match
QUERYSTRING=$(cddbcmd -h freedb.freedb.org cddb query $(cd-discid) | awk 'NR == 1 {print $1,$2}');

while read line; do
	INDEX=${line%%=*};
	VALUE=${line#*=};
	case "$INDEX" in
		#extract Disc Title
		DTITLE)
			artistName="${VALUE%% /*}";	#everything before " /"
			albumName="${VALUE#*/ }";	#everything after "/ "
		;;
		#Extract Track names
		TTITLE*)
			trackNum=${INDEX#TTITLE};	    #remove TTITLE from the front to leave the number
			trackNum=$(($trackNum + 1));	#0 based to 1 based
			trackNames[${trackNum}]="$VALUE";
		;;
		#Ignore everything else
		*)	;;
	esac
done < <(cddbcmd -h freedb.freedb.org cddb read ${QUERYSTRING});

rm *.cdda.wav

cdparanoia -B

tracknum=1;
for f in track*.cdda.wav; do

	lame -m j --replaygain-accurate -h -q 0 --vbr-new -V 0 -b 192 \
			--ta "${artistName}" --tl "${albumName}" --tn "${tracknum}" \
			--tt "${trackNames[${tracknum}]}" --add-id3v2 \
			"${f}" "${f/%wav/mp3}";

	##not entirely sure that --replaygain-accurate does what I want/need so I'll reapply
	mp3gain -r -c -d 3.0 "${f/%wav/mp3}";

	#Rename target MP3
	displaytracknum=$(printf "%02i" "${tracknum}");
	mv -n "${f/%wav/mp3}" "${artistName} - ${albumName} - ${displaytracknum} - ${trackNames[$tracknum]}.mp3"

	tracknum=$(($tracknum+1));
done

echo "CD Ripped, and should be here: ${TEMPDIR}/*.mp3"
eject /dev/cdrom

popd
