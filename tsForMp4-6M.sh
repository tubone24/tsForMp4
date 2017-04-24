#!/bin/sh
tsFolder="/media/ts/"
mp4Folder="/media/mp4/"
counter=0
while :
do
  cd $(echo $tsFolder)
  if [ $(ls *.m2ts | wc -l) -gt 0 ] ; then
    targetFileName="$(find  $(echo $tsFolder)*.m2ts | head -n 1)"
    tmpMp4FileName=/tmp/$(basename $(echo $targetFileName | sed 's/.m2ts/.mp4/g'))
    newMp4FileName=$(echo $mp4Folder)$(basename $(echo $targetFileName | sed 's/.m2ts/.mp4/g'))
    echo "$(echo $targetFileName) encording... to $(echo $tmpMp4FileName) 開始時刻: $(date +"%Y/%m/%d %p %I:%M:%S")"
    ~/bin/ffmpeg -i $(echo $targetFileName) -loglevel warning -threads 2 \
    -codec:v libx264 -c:a aac -profile:v high -level 4.0 -preset veryslow -tune animation -crf 19 -s 1440x1080 -b:a 192k \
    -y -f mp4 \
    $(echo $tmpMp4FileName)
    if [ $? = 0 ]; then
      echo "正常にエンコード終了 move from $(echo $tmpMp4FileName) to $(echo $tmpMp4FileName)"
      mv $(echo $tmpMp4FileName) $(echo $newMp4FileName)
      if [ $? = 0 ]; then
        counter=$(( counter + 1 ))
        echo "エンコード元TSファイルを削除します 新規ファイル $(echo $newMp4FileName) 終了時刻: $(date +"%Y/%m/%d %p %I:%M:%S")"
        rm $(echo $targetFileName)
      else
        echo "error move exit(-1) $(echo $tmpMp4FileName)" 1>&2
        exit 1
      fi
    else
      echo "エンコードに失敗した模様... スクリプトを終了します" 1>&2
      exit 1
    fi
  else
    echo "エンコード対象ファイルが見つかりません。スクリプトを終了します"
    echo "エンコード済みファイル数 $(echo $counter)"
    exit 0
  fi
done
