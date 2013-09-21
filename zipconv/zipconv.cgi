#!/usr/bin/perl -Tw

use strict;
use vars qw(%CONF %FORM $dbh);
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "jcode.pl";
require "./lib.pl";
umask 0;

$ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

%FORM = decoding(new CGI);

$dbh = _init_db();

$FORM{zip} = zen_to_han($FORM{zip});
$FORM{zip} =~ s/\-//g;
$FORM{i} ||= 0;
error_close("郵便番号は半角数字で指定してください。") if $FORM{zip} =~ /\D/;
error_close("郵便番号は3ケタ以上指定してください。") if length($FORM{zip}) < 3;

my $cnt = 0;
my %prefcode = map { $_ => ++$cnt } qw(北海道 青森県 岩手県 宮城県 秋田県 山形県 福島県 茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県 山梨県 長野県 新潟県 富山県 石川県 福井県 岐阜県 静岡県 愛知県 三重県 滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県 鳥取県 島根県 岡山県 広島県 山口県 徳島県 香川県 愛媛県 高知県 福岡県 佐賀県 長崎県 熊本県 大分県 宮崎県 鹿児島県 沖縄県);

my $list;
$cnt = 0;
my $onload;
foreach my $row(sql_selectall($dbh, "select zip,pref,city,addr from zip2 where " . (length($FORM{zip}) == 7 ? "zip='$FORM{zip}'" : "zip like '$FORM{zip}%'") . "order by zip")) {
    foreach (qw(pref city addr)) {
        jcode::convert(\$row->{$_}, "sjis", "euc");
    }
    $row->{zip} =~ s/(\d{3})(\d{4})/$1-$2/;
    $list .= <<STR;
<tr><th>$row->{zip}</th><td><a href="javascript:datainput('$FORM{mode}','$row->{zip}','$prefcode{$row->{pref}}','$row->{city}','$row->{addr}','$FORM{i}')">$row->{pref} $row->{city} $row->{addr}</a></td></tr>
STR
    $cnt++;
    $onload ||= $row;
}

$list = "<tr><th>該当するデータがありません</th></tr>" unless $cnt;
if ($cnt == 1) {
    $onload = "datainput('$FORM{mode}','$onload->{zip}','$prefcode{$onload->{pref}}','$onload->{city}','$onload->{addr}','$FORM{i}')";
} else {
    $onload = "";
}

printhtml("tmpl/_zipconv.html", list=>$list, onload=>$onload);
exit;

