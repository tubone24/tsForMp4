#tsForMp4

## 概要
録画機で録画したtsファイル(m2ts)に対して、comskipを使いCMカットをし、
カットしたCMに対してH.264でエンコードします。

## 必須条件
以下のものがインストールされている必要があります。
* ffmpeg(H.264 ACCのライブラリもビルドされていること)
* comskip
* wine(comskip はEXEファイルなのでWindowsをエミュレートします)

## お借りした資源
### cmcut.pl
https://www.jifu-labo.net/2015/12/comskip_wine32/
こちらで掲載されているCMカットスクリプトを利用しました。
ありがとうございます。

## 使い方
まず、環境を整えます。



