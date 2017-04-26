#!/bin/sh
tsFolder="/media/ts/"
mp4Folder="/media/mp4/"
tmpFolder="/media/tmp/"
counter=0
mkdir $(echo $tmpFolder)/cut
while :
do
  cd $(echo $tsFolder)
  if [ $(ls *.m2ts | wc -l) -gt 0 ] ; then
    targetFileName="$(find  $(echo $tsFolder)*.m2ts | head -n 1)"
    tmpTsFileName="$(echo $tmpFolder)$(basename $(echo $targetFileName))"
    tmpTscutFileName="$(echo $tmpFolder)cut/$(basename $(echo $targetFileName))"
    tmpMp4FileName="$(echo $tmpFolder)$(basename $(echo $targetFileName | sed 's/.m2ts/.mp4/g'))"
    newMp4FileName="$(echo $mp4Folder)$(basename $(echo $targetFileName | sed 's/.m2ts/.mp4/g'))"
    echo "$(echo $targetFileName) encording... to $(echo $tmpMp4FileName) 開始時刻: $(date +"%Y/%m/%d %p %I:%M:%S")"
    cp $targetFileName $tmpTsFileName
    if [ $? = 0 ] ; then
      mv $targetFileName "$tsFolder$(basename $(echo $targetFileName | sed 's/.m2ts/.ts/g'))"
      if [ $? = 0 ] ; then
        echo "CMカットします"
        ~/tsForMp4/cmcut.pl -i $tmpTsFileName -o $tmpTscutFileName
        if [ $? = 0 ] ; then
          echo "CMカット成功"
          ~/bin/ffmpeg -i $(echo $tmpTscutFileName) -loglevel error -threads 2 \
          -codec:v libx264 -c:a aac -profile:v high -level 4.0 -preset veryslow -tune animation -crf 18 -s 1440x1080 -b:a 192k \
          -y -f mp4 \
          $(echo $tmpMp4FileName)
          if [ $? = 0 ]; then
            echo "正常にエンコード終了"
            mv  $tmpMp4FileName $(echo $newMp4FileName)
            if [ $? = 0 ]; then
              counter=$(( counter + 1 ))
              echo "エンコード元TSファイルを削除します 新規ファイル $(echo $newMp4FileName) 終了時刻: $(date +"%Y/%m/%d %p %I:%M:%S")"
              echo "合計エンコードファイル数 $(echo $counter)"
              rm $(echo $tmpTscutFileName)
              if [ $? = 0 ]; then
                rm $(echo $tsFolder)$(echo $(basename $(echo $targetFileName | sed 's/.m2ts/.ts/g')))
              else
                echo "tmpTSファイルの削除失敗"
                exit 1
              fi
          else
            echo "エンコードに失敗した模様... スクリプトを終了します" 1>&2
            exit 1
          fi
        else
          echo "CMカット失敗"
          exit 1
        fi
      else
        echo "指定ファイルのリネームに失敗しました。"
        exit 1
      fi
    else
      echo "指定ファイルのコピーに失敗しました。。"
      exit 1
    fi
  else
    echo "エンコード対象ファイルが見つかりません。スクリプトを終了します"
    echo "エンコード済みファイル数 $(echo $counter)"
    exit 0
  fi
fi
done

