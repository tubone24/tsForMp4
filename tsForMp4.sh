#!/bin/sh
tsFolder="/mnt/usbhdd1/chinachu/ts/"
mp4Folder="/mnt/usbhdd1/chinachu/mp4/"
counter=0
while :
do
  if [ -e $(echo $tsFolder)*.m2ts ]; then
    targetFileName=$(find  $(echo $tsFolder)*.m2ts | head -n 1)
    newMp4FileName=$(echo $mp4Folder)$(basename $(echo $targetFileName | sed 's/.m2ts/.mp4/g'))
    echo "$(echo $targetFileName) encording... to $(echo $newMp4FileName)"
    /home/chinachu/chinachu/usr/bin/ffmpeg -v 0 -re -i $(echo $targetFileName) -ss 2 -threads auto -c:v libx264 -c:a aac -s 1920x1080 -filter:v yadif -b:v 3M -b:a 192k -profile:v baseline -preset ultrafast -tune fastdecode,zerolatency -movflags frag_keyframe+empty_moov+faststart+default_base_moof -y -f mp4 $(echo $newMp4FileName)
    if [ $? = 0 ]; then
      echo "正常にエンコード終了"
      counter=$(( counter + 1 ))
    else
      echo "エンコードに失敗した模様... スクリプトを終了します"
      exit 1
    fi
  else
    echo "エンコード対象ファイルが見つかりません。スクリプトを終了します"
    echo "エンコード済みファイル数 $(echo $counter)"
    exit 0
  fi
done
