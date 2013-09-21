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
error_close("�X�֔ԍ��͔��p�����Ŏw�肵�Ă��������B") if $FORM{zip} =~ /\D/;
error_close("�X�֔ԍ���3�P�^�ȏ�w�肵�Ă��������B") if length($FORM{zip}) < 3;

my $cnt = 0;
my %prefcode = map { $_ => ++$cnt } qw(�k�C�� �X�� ��茧 �{�錧 �H�c�� �R�`�� ������ ��錧 �Ȗ،� �Q�n�� ��ʌ� ��t�� �����s �_�ސ쌧 �R���� ���쌧 �V���� �x�R�� �ΐ쌧 ���䌧 �򕌌� �É��� ���m�� �O�d�� ���ꌧ ���s�{ ���{ ���Ɍ� �ޗǌ� �a�̎R�� ���挧 ������ ���R�� �L���� �R���� ������ ���쌧 ���Q�� ���m�� ������ ���ꌧ ���茧 �F�{�� �啪�� �{�茧 �������� ���ꌧ);

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

$list = "<tr><th>�Y������f�[�^������܂���</th></tr>" unless $cnt;
if ($cnt == 1) {
    $onload = "datainput('$FORM{mode}','$onload->{zip}','$prefcode{$onload->{pref}}','$onload->{city}','$onload->{addr}','$FORM{i}')";
} else {
    $onload = "";
}

printhtml("tmpl/_zipconv.html", list=>$list, onload=>$onload);
exit;

