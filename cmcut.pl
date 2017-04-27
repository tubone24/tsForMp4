#!/usr/bin/perl
 
use strict;
use warnings;
use utf8;
use open ":utf8";
use Encode;
use File::Basename qw/basename dirname/;
use Getopt::Long;
use Time::Local;
use File::Copy;
 
$SIG{'INT'}  = \&handler;
$SIG{'KILL'} = \&handler;
my %opts = ();
my $script_name = basename $0;
 
# ************************
# ***** ユーザー設定 *****
# ************************
# comskipの実行ファイル名
my $comskip_cmd = "/usr/bin/wine /opt/comskip_batch/comskip/comskip.exe";
 
# ffmpegの実行ファイル名
my $ffmpeg_cmd = "/home/tubone/bin/ffmpeg";
 
# 先頭のマージン秒 (59秒以内)
my $margin_sec = 1;
 
# comskipのCM検出方法
my $detect_flag = 198;
 
# comskipの初期設定ファイル
my $ini_file = "/opt/comskip_batch/comskip/comskip.ini";
 
# ************************
# ***** 設定ここまで *****
# ************************
 
#binmode(STDOUT, ":utf8");
 
# 関数: ヘルプ
sub usage {
    no utf8;
 
    print <<END;
Usage:
  comskipで検出したCM位置を元にMPEG2-TSファイルからCMをカットして出力する
 
書式
  $script_name -i|-input <file> -o|-output <file> [-h|-help] [-m|-margin <int>] [-d|-detectmethod <int>] [-force|f] [-ini <file>] [-int|-intermediate <int>] [-logo|-l <file>] [-t|-test]
 
  -h, -help                  本内容の表示
  -i, -input <file>          入力 MPEG2-TS ファイル名(必須)
  -o, -output <file>         CMカット後の出力 MPEG2-TS ファイル名(必須)
  -m, -margin <int>          入力ファイルの先頭のマージン秒(59秒以内)
  -d, -detectmethod <int>    comskipのCM検出方法(詳細はcomskipの同オプション参照)
  -f, -force                 CMカットに失敗しても、強制的に入力ファイルのコピーを出力
  -ini <file>                comskipのiniファイル
  -int, -intermediate <int>  中間ファイルの削除有無
                              1:全削除(default), 2:vdrとlogoファイルのみ保存, 3:全て残す
  -l, -logo <file>           comskipのロゴファイル
  -t, -test                  CM検出範囲の時間を表示して終了する
注意事項
  - マージン秒、comskipのCM検出方法、iniファイルのデフォルト設定は
    本スクリプト内の該当パラメータにてユーザーが設定する
END
 
    exit(0);
}
 
# 関数: msec単位の時刻取得(1900年1月1日基準)
sub time2msec {
    my($time1) = @_;
    my($msec_time);
    my($hour, $min, $sec, $msec);
 
    ($hour, $min, $sec, $msec) = split(/[:\.]/, $time1);
 
    $msec_time = timelocal($sec, $min, $hour, 1, 0, 0);
    $msec_time += ($msec/100);
 
    return $msec_time;
}
 
GetOptions(\%opts, qw(help|h input|i=s output|o=s margin|m=i detectmethod|d=i ini=s intermediate|int=i logo|l=s force|f test|t))
    or die "Error(GetOptions)";
 
# 入出力ファイル指定
unless (exists $opts{'input'} && exists $opts{'output'}) {
    &usage();
} elsif (exists $opts{'help'}) {
    &usage();
}
 
my $input_ts  = decode('utf8', $opts{'input'});
my $output_ts = decode('utf8', $opts{'output'});
my $base_name = basename $input_ts;
$base_name =~ s/\.[^\.]+$//;
my $base_dir  = dirname $input_ts;
 
if ($input_ts eq $output_ts) {
    die "input and output file is same.";
}
 
# マージン秒指定
if (exists $opts{'margin'} && $opts{'margin'} < 60) {
    $margin_sec = $opts{'margin'};
}
my $margin_time = sprintf("0:00:%02d.00", $margin_sec);
 
# comskipの初期設定ファイル指定
if (exists $opts{'ini'}) {
    $ini_file = $opts{'ini'};
}
 
# comskipのCM検出方法指定
if (exists $opts{'detectmethod'}) {
    $detect_flag = $opts{'detectmethod'};
}
 
# comskipの中間ファイルの削除有無
use constant {ALL_DELETE => 1, REMAIN_VDR => 2, REMAIN_ALL => 3,};
my $intermediate_flag = ALL_DELETE;
if (exists $opts{'intermediate'}) {
    $intermediate_flag = $opts{'intermediate'};
}
 
# comskipの実行
$comskip_cmd .= " -t -d $detect_flag -v 1 --ini=$ini_file";
if (exists $opts{'logo'}) {
    $comskip_cmd .= " --logo=";
    $comskip_cmd .= $opts{'logo'};
}
$comskip_cmd .= " \"$input_ts\"";
`$comskip_cmd`;
 
my $vdr_file = "$base_dir/${base_name}.vdr";
unless (-f $vdr_file) {
    &handler("can't make a vdr file.");
}
 
# TSファイルの記録時間取得
my $result = `$ffmpeg_cmd -i "$input_ts" 2>&1 | grep Duration`;
$result =~ /Duration: (\d+:\d+:\d+\.\d+)/;
my $end_time = $1;
 
# vdrの解析(配列の作成)
my @rec_time = ();
 
open(my $vdr_handle, "<", $vdr_file)
    or &handler("can't open $vdr_file: $!");
 
print "vdr output\n--------------------\n" if (exists $opts{'test'});
 
foreach my $line (<$vdr_handle>) {
    print "  $line" if (exists $opts{'test'});
    chomp($line);
    $line =~ s/\s+start.*$//;
    $line =~ s/\s+end.*$//;
 
    push(@rec_time, $line);
}
 
close($vdr_handle);
 
if ($#rec_time < 0) {
    &handler("can't detect CM.");
}
 
print "\$#rec_time = ", $#rec_time, "\n"; 
 
if (&time2msec($rec_time[0]) == &time2msec($margin_time)) {
    shift(@rec_time);
} elsif (&time2msec($rec_time[0]) > &time2msec($margin_time)) {
    unshift(@rec_time, $margin_time);
} else {
    shift(@rec_time);
    while (my $tmp = shift @rec_time) {
    if (&time2msec($tmp) > &time2msec($margin_time)) {
        unless ($#rec_time % 2) {
        unshift(@rec_time, $tmp);
        unshift(@rec_time, $margin_time);
        } else {
        unshift(@rec_time, $tmp);
        }
        last;
    }
    }
}
 
if ($#rec_time < 0) {
    push(@rec_time, $margin_time);
}
 
if (abs(&time2msec($end_time) - &time2msec($rec_time[-1])) < 3) {
    # 最後の検出時間が終端から3秒以内ならば要素を削除
    pop(@rec_time);
} else {
    # それ以外は記録時間を終端に追加
    push(@rec_time, $end_time);
}
 
unless ($#rec_time % 2) {
    # 配列要素数が奇数ならば終了
    $intermediate_flag = REMAIN_VDR;
    &handler("invalid vdr");
}
 
if (exists $opts{'test'}) {
    print "\nprogram interval\n--------------------\n";
    for (my $i=0; $i<$#rec_time/2; $i++) {
    print "  $i: ", $rec_time[$i*2], " to ", $rec_time[$i*2+1], "\n";
    }
    &handler();
}
 
# 動画本編の切り出し
my @concat_file = ();
my $pre_time = time;
for (my $i=0; $i<$#rec_time/2; $i++) {
    my $duration = sprintf("%.2f", &time2msec($rec_time[$i*2+1]) - &time2msec($rec_time[$i*2]));
    my $tmp_file = "$base_dir/${pre_time}_10${i}.ts";
    my $cut_cmd = sprintf("%s -y -i \"%s\" -ss %s -t %s -c copy -sn %s",
              $ffmpeg_cmd, $input_ts, $rec_time[$i*2], $duration, $tmp_file);
    push(@concat_file, $tmp_file);
    print $cut_cmd, "\n";
    system($cut_cmd);
    if ($? != 0) {
    &handler("ffmpeg error: $!");
    }
}
 
my $concat_par = "concat:". join('|', @concat_file);
print "$concat_par\n";
 
# 全TSファイルの結合(ffmpeg concat)
my $concat_cmd = "${ffmpeg_cmd} -y -i \"${concat_par}\" -c copy \"${output_ts}\"";
print "$concat_cmd\n";
system($concat_cmd);
if ($? != 0) {
    print "ffmpeg error: $!";
}
 
&handler();
 
sub handler
{
    my($msg) = @_;
    my($exit_num) = 0;
 
    if ($intermediate_flag == ALL_DELETE || $intermediate_flag == REMAIN_VDR) {
    unlink("$base_dir/${base_name}.txt");
    unlink("$base_dir/${base_name}.log");
    unlink("$base_dir/${base_name}.ts.avs");
    unlink("$base_dir/${base_name}.ts.chapters.xml");
    if ($intermediate_flag == ALL_DELETE) {
        unlink($vdr_file);
        unlink("$base_dir/${base_name}.logo.txt");
    }
    }
 
    if ($intermediate_flag != REMAIN_ALL) {
    foreach (@concat_file) {
        unlink($_);
    }
    }
 
    if (length($msg)) {
    print $msg, "\n";
    if (!exists $opts{'test'} && exists $opts{'force'}) {
        copy($input_ts, $output_ts);
    } else {
        $exit_num = 1;
    }
    }
 
    exit($exit_num);
}
