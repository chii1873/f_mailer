#
# FORM MAILER v0.63 設定ファイル
# (c)1997-2013 Perl Script Laboratory All rights reserved.
#
# sample.pl
#
# このファイルはプログラムによって自動生成されました。
# 生成日時: 2013-05-07 00:13:37

package conf;
#use utf8;

 sub conf {

    my %conf;

    chomp($conf{label} = <<'_STR_label_');
サンプル
_STR_label_
    chomp($conf{LANG} = <<'_STR_LANG_');
ja
_STR_LANG_
    chomp($conf{TITLE} = <<'_STR_TITLE_');
フォームの送信
_STR_TITLE_
    chomp($conf{CONFIRM_FLAG} = <<'_STR_CONFIRM_FLAG_');
1
_STR_CONFIRM_FLAG_
    chomp($conf{CONFIRM_TMPL} = <<'_STR_CONFIRM_TMPL_');
./tmpl/custom/confirm.html
_STR_CONFIRM_TMPL_
    chomp($conf{CONFIRM_TMPL_CHARSET} = <<'_STR_CONFIRM_TMPL_CHARSET_');
utf8
_STR_CONFIRM_TMPL_CHARSET_
    chomp($conf{CONFIRM_TMPL_BASE_URL} = <<'_STR_CONFIRM_TMPL_BASE_URL_');

_STR_CONFIRM_TMPL_BASE_URL_
    chomp($conf{ERROR_FLAG} = <<'_STR_ERROR_FLAG_');
0
_STR_ERROR_FLAG_
    chomp($conf{ERROR_TMPL} = <<'_STR_ERROR_TMPL_');
./tmpl/custom/error.html
_STR_ERROR_TMPL_
    chomp($conf{ERROR_TMPL_CHARSET} = <<'_STR_ERROR_TMPL_CHARSET_');
utf8
_STR_ERROR_TMPL_CHARSET_
    chomp($conf{ERROR_TMPL_BASE_URL} = <<'_STR_ERROR_TMPL_BASE_URL_');

_STR_ERROR_TMPL_BASE_URL_
    chomp($conf{FORM_FLAG} = <<'_STR_FORM_FLAG_');
1
_STR_FORM_FLAG_
    chomp($conf{FORM_TMPL} = <<'_STR_FORM_TMPL_');
f_mailer_form.html
_STR_FORM_TMPL_
    chomp($conf{FORM_TMPL_CHARSET} = <<'_STR_FORM_TMPL_CHARSET_');
utf8
_STR_FORM_TMPL_CHARSET_
    chomp($conf{FORM_TMPL_BASE_URL} = <<'_STR_FORM_TMPL_BASE_URL_');

_STR_FORM_TMPL_BASE_URL_
    chomp($conf{BLANK_STR} = <<'_STR_BLANK_STR_');

_STR_BLANK_STR_
    chomp($conf{COND}[0][0] = <<'_STR_COND_');
name
_STR_COND_
    chomp($conf{COND}[0][1]{type} = <<'_STR_COND_');
text
_STR_COND_
    chomp($conf{COND}[0][1]{required} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[0][1]{alt} =<<'_STR_COND_');
お名前
_STR_COND_
    chomp($conf{COND}[0][1]{h2z_kana} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[1][0] = <<'_STR_COND_');
kana
_STR_COND_
    chomp($conf{COND}[1][1]{type} = <<'_STR_COND_');
text
_STR_COND_
    chomp($conf{COND}[1][1]{required} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[1][1]{alt} =<<'_STR_COND_');
フリガナ
_STR_COND_
    chomp($conf{COND}[1][1]{kata_only} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[2][0] = <<'_STR_COND_');
sex
_STR_COND_
    chomp($conf{COND}[2][1]{type} = <<'_STR_COND_');
radio
_STR_COND_
    chomp($conf{COND}[2][1]{required} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[2][1]{alt} =<<'_STR_COND_');
性別
_STR_COND_
    chomp($conf{COND}[3][0] = <<'_STR_COND_');
EMAIL
_STR_COND_
    chomp($conf{COND}[3][1]{type} = <<'_STR_COND_');
text
_STR_COND_
    chomp($conf{COND}[3][1]{required} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[3][1]{alt} =<<'_STR_COND_');
メールアドレス
_STR_COND_
    chomp($conf{COND}[3][1]{z2h} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[3][1]{email} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[3][1]{compare} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[4][0] = <<'_STR_COND_');
EMAIL2
_STR_COND_
    chomp($conf{COND}[4][1]{type} = <<'_STR_COND_');
text
_STR_COND_
    chomp($conf{COND}[4][1]{required} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[4][1]{alt} =<<'_STR_COND_');
メールアドレス確認用
_STR_COND_
    chomp($conf{COND}[4][1]{z2h} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[5][0] = <<'_STR_COND_');
pcode
_STR_COND_
    chomp($conf{COND}[5][1]{type} = <<'_STR_COND_');
text
_STR_COND_
    chomp($conf{COND}[5][1]{required} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[5][1]{alt} =<<'_STR_COND_');
郵便番号
_STR_COND_
    chomp($conf{COND}[5][1]{z2h} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[5][1]{regex2} =<<'_STR_COND_');
\d{3}\-\d{4}
_STR_COND_
    chomp($conf{COND}[6][0] = <<'_STR_COND_');
pref
_STR_COND_
    chomp($conf{COND}[6][1]{type} = <<'_STR_COND_');
select
_STR_COND_
    chomp($conf{COND}[6][1]{required} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[6][1]{alt} =<<'_STR_COND_');
都道府県
_STR_COND_
    chomp($conf{COND}[7][0] = <<'_STR_COND_');
city
_STR_COND_
    chomp($conf{COND}[7][1]{type} = <<'_STR_COND_');
text
_STR_COND_
    chomp($conf{COND}[7][1]{required} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[7][1]{alt} =<<'_STR_COND_');
市区名等
_STR_COND_
    chomp($conf{COND}[8][0] = <<'_STR_COND_');
addr
_STR_COND_
    chomp($conf{COND}[8][1]{type} = <<'_STR_COND_');
text
_STR_COND_
    chomp($conf{COND}[8][1]{required} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[8][1]{alt} =<<'_STR_COND_');
住所/マンション等
_STR_COND_
    chomp($conf{COND}[8][1]{z2h} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[8][1]{h2z_kana} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[9][0] = <<'_STR_COND_');
tel
_STR_COND_
    chomp($conf{COND}[9][1]{type} = <<'_STR_COND_');
text
_STR_COND_
    chomp($conf{COND}[9][1]{required} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[9][1]{alt} =<<'_STR_COND_');
電話番号
_STR_COND_
    chomp($conf{COND}[9][1]{z2h} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[9][1]{regex} =<<'_STR_COND_');
[^0-9-]
_STR_COND_
    chomp($conf{COND}[10][0] = <<'_STR_COND_');
rel
_STR_COND_
    chomp($conf{COND}[10][1]{type} = <<'_STR_COND_');
text
_STR_COND_
    chomp($conf{COND}[10][1]{alt} =<<'_STR_COND_');
機種依存文字判定
_STR_COND_
    chomp($conf{COND}[10][1]{deny_rel} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[11][0] = <<'_STR_COND_');
url
_STR_COND_
    chomp($conf{COND}[11][1]{type} = <<'_STR_COND_');
text
_STR_COND_
    chomp($conf{COND}[11][1]{alt} =<<'_STR_COND_');
URL判定
_STR_COND_
    chomp($conf{COND}[11][1]{z2h} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[11][1]{url} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[12][0] = <<'_STR_COND_');
q1
_STR_COND_
    chomp($conf{COND}[12][1]{type} = <<'_STR_COND_');
checkbox
_STR_COND_
    chomp($conf{COND}[12][1]{alt} =<<'_STR_COND_');
複数回答
_STR_COND_
    chomp($conf{COND}[12][1]{max} =<<'_STR_COND_');
3
_STR_COND_
    chomp($conf{COND}[13][0] = <<'_STR_COND_');
pts
_STR_COND_
    chomp($conf{COND}[13][1]{type} = <<'_STR_COND_');
text
_STR_COND_
    chomp($conf{COND}[13][1]{alt} =<<'_STR_COND_');
数値範囲
_STR_COND_
    chomp($conf{COND}[13][1]{z2h} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[13][1]{d_only} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[13][1]{min} =<<'_STR_COND_');
25
_STR_COND_
    chomp($conf{COND}[13][1]{max} =<<'_STR_COND_');
75
_STR_COND_
    chomp($conf{COND}[14][0] = <<'_STR_COND_');
message
_STR_COND_
    chomp($conf{COND}[14][1]{type} = <<'_STR_COND_');
textarea
_STR_COND_
    chomp($conf{COND}[14][1]{alt} =<<'_STR_COND_');
メッセージ
_STR_COND_
    chomp($conf{COND}[14][1]{trim2} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[14][1]{h2z_kana} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[15][0] = <<'_STR_COND_');
att1
_STR_COND_
    chomp($conf{COND}[15][1]{type} = <<'_STR_COND_');
file
_STR_COND_
    chomp($conf{COND}[15][1]{alt} =<<'_STR_COND_');
添付ファイル1
_STR_COND_
    chomp($conf{COND}[15][1]{attach} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[16][0] = <<'_STR_COND_');
att2
_STR_COND_
    chomp($conf{COND}[16][1]{type} = <<'_STR_COND_');
file
_STR_COND_
    chomp($conf{COND}[16][1]{alt} =<<'_STR_COND_');
添付ファイル2
_STR_COND_
    chomp($conf{COND}[16][1]{attach} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[17][0] = <<'_STR_COND_');
att3
_STR_COND_
    chomp($conf{COND}[17][1]{type} = <<'_STR_COND_');
file
_STR_COND_
    chomp($conf{COND}[17][1]{alt} =<<'_STR_COND_');
添付ファイル3
_STR_COND_
    chomp($conf{COND}[17][1]{attach} =<<'_STR_COND_');
1
_STR_COND_
    chomp($conf{COND}[18][0] = <<'_STR_COND_');
SERIAL
_STR_COND_
    chomp($conf{COND}[18][1]{alt} = <<'_STR_COND_');
受付番号
_STR_COND_
    chomp($conf{COND}[19][0] = <<'_STR_COND_');
REMOTE_HOST
_STR_COND_
    chomp($conf{COND}[19][1]{alt} = <<'_STR_COND_');
接続元ホスト
_STR_COND_
    chomp($conf{COND}[20][0] = <<'_STR_COND_');
REMOTE_ADDR
_STR_COND_
    chomp($conf{COND}[20][1]{alt} = <<'_STR_COND_');
IPアドレス
_STR_COND_
    chomp($conf{COND}[21][0] = <<'_STR_COND_');
USER_AGENT
_STR_COND_
    chomp($conf{COND}[21][1]{alt} = <<'_STR_COND_');
ブラウザ名
_STR_COND_
    chomp($conf{COND}[22][0] = <<'_STR_COND_');
NOW_DATE
_STR_COND_
    chomp($conf{COND}[22][1]{alt} = <<'_STR_COND_');
送信日時
_STR_COND_
    chomp($conf{THANKS_FLAG} = <<'_STR_THANKS_FLAG_');
1
_STR_THANKS_FLAG_
    chomp($conf{THANKS} = <<'_STR_THANKS_');
http://xxx.yy.zz/thanks.html
_STR_THANKS_
    chomp($conf{THANKS_TMPL} = <<'_STR_THANKS_TMPL_');
./tmpl/custom/thanks.html
_STR_THANKS_TMPL_
    chomp($conf{THANKS_TMPL_CHARSET} = <<'_STR_THANKS_TMPL_CHARSET_');
utf8
_STR_THANKS_TMPL_CHARSET_
    chomp($conf{THANKS_TMPL_BASE_URL} = <<'_STR_THANKS_TMPL_BASE_URL_');

_STR_THANKS_TMPL_BASE_URL_
    chomp($conf{DENY_DUPL_SEND} = <<'_STR_DENY_DUPL_SEND_');
1
_STR_DENY_DUPL_SEND_
    chomp($conf{DENY_DUPL_SEND_MIN} = <<'_STR_DENY_DUPL_SEND_MIN_');
60
_STR_DENY_DUPL_SEND_MIN_
    chomp($conf{SENDTO} = <<'_STR_SENDTO_');
chii1873@gmail.com
iwanami@j-epoch.com
chii1873@softbank.ne.jp
_STR_SENDTO_
    chomp($conf{DO_NOT_SEND} = <<'_STR_DO_NOT_SEND_');

_STR_DO_NOT_SEND_
    chomp($conf{SENDFROM} = <<'_STR_SENDFROM_');
xxxxx@yyy.zz
_STR_SENDFROM_
    chomp($conf{ENVELOPE_ADDR} = <<'_STR_ENVELOPE_ADDR_');

_STR_ENVELOPE_ADDR_
    chomp($conf{ENVELOPE_ADDR_LINK} = <<'_STR_ENVELOPE_ADDR_LINK_');

_STR_ENVELOPE_ADDR_LINK_
    chomp($conf{SUBJECT} = <<'_STR_SUBJECT_');
フォームの送信
_STR_SUBJECT_
    $conf{ATTACH_EXT} = [qw(jpg jpeg png txt html gif pdf doc xls)];
    $conf{ATTACH_FIELDNAME} = [qw(att1 att2 att3)];
    chomp($conf{ATTACH_SIZE_MAX} = <<'_STR_ATTACH_SIZE_MAX_');
512
_STR_ATTACH_SIZE_MAX_
    chomp($conf{ATTACH_TSIZE_MAX} = <<'_STR_ATTACH_TSIZE_MAX_');
1536
_STR_ATTACH_TSIZE_MAX_
    chomp($conf{MAIL_FORMAT_TYPE} = <<'_STR_MAIL_FORMAT_TYPE_');
1
_STR_MAIL_FORMAT_TYPE_
    chomp($conf{FORMAT} = <<'_STR_FORMAT_');
フォームの送信

受付番号：##SERIAL##

メールアドレス：##EMAIL##
お名前：##name## (##kana##)  性別：##sex##
住  所：〒##pcode## ##addr##
ＴＥＬ：##tel##
機種依：##rel##
ＵＲＬ：##url##
問1の答え：##q1::h##
予想得点 ：##pts##点
感     想：
  ##message:2##
添付ファイル1：##att1##
            2：##att2##
            3：##att3##
--------------------------------------------------------
送信日時    ：##NOW_DATE##
接続元ホスト：##REMOTE_HOST##
使用ブラウザ：##USER_AGENT##
--------------------------------------------------------
_STR_FORMAT_
    chomp($conf{MARK} = <<'_STR_MARK_');
●
_STR_MARK_
    chomp($conf{SEPR} = <<'_STR_SEPR_');
：
_STR_SEPR_
    chomp($conf{OFT} = <<'_STR_OFT_');
20
_STR_OFT_
    chomp($conf{AUTO_REPLY} = <<'_STR_AUTO_REPLY_');
1
_STR_AUTO_REPLY_
    chomp($conf{REPLY_SENDFROM} = <<'_STR_REPLY_SENDFROM_');
xxxxx@yyy.zz
_STR_REPLY_SENDFROM_
    chomp($conf{REPLY_SENDFROMNAME} = <<'_STR_REPLY_SENDFROMNAME_');
送信元
_STR_REPLY_SENDFROMNAME_
    chomp($conf{REPLY_ENVELOPE_ADDR} = <<'_STR_REPLY_ENVELOPE_ADDR_');

_STR_REPLY_ENVELOPE_ADDR_
    chomp($conf{REPLY_SUBJECT} = <<'_STR_REPLY_SUBJECT_');
お申し込みありがとうございます。
_STR_REPLY_SUBJECT_
    chomp($conf{REPLY_MAIL_FORMAT_TYPE} = <<'_STR_REPLY_MAIL_FORMAT_TYPE_');
1
_STR_REPLY_MAIL_FORMAT_TYPE_
    chomp($conf{REPLY_FORMAT} = <<'_STR_REPLY_FORMAT_');
##name## さま

送信ありがとうございます。

あなたの受付番号は ##SERIAL## です。

メールアドレス：##EMAIL##
お名前：##name## (##kana##)
性  別：##sex##
住  所：〒##pcode## ##addr##
ＴＥＬ：##tel##
機種依：##rel##
ＵＲＬ：##url##
問1の答え：##q1::h##
予想得点 ：##pts##点
感     想：
  ##message:2##
添付ファイル1：##att1##
            2：##att2##
            3：##att3##
--------------------------------------------------------
送信日時    ：##NOW_DATE##
接続元ホスト：##REMOTE_HOST##
使用ブラウザ：##USER_AGENT##
--------------------------------------------------------
_STR_REPLY_FORMAT_
    chomp($conf{REPLY_MARK} = <<'_STR_REPLY_MARK_');
●
_STR_REPLY_MARK_
    chomp($conf{REPLY_SEPR} = <<'_STR_REPLY_SEPR_');
：
_STR_REPLY_SEPR_
    chomp($conf{REPLY_OFT} = <<'_STR_REPLY_OFT_');
20
_STR_REPLY_OFT_
    chomp($conf{FILE_OUTPUT} = <<'_STR_FILE_OUTPUT_');
1
_STR_FILE_OUTPUT_
    chomp($conf{OUTPUT_FILENAME} = <<'_STR_OUTPUT_FILENAME_');
./data/output.txt
_STR_OUTPUT_FILENAME_
    chomp($conf{OUTPUT_SEPARATOR} = <<'_STR_OUTPUT_SEPARATOR_');
0
_STR_OUTPUT_SEPARATOR_
    $conf{OUTPUT_FIELDS} = [qw(
)];
    chomp($conf{FIELD_SEPARATOR} = <<'_STR_FIELD_SEPARATOR_');
,
_STR_FIELD_SEPARATOR_
    chomp($conf{NEWLINE_REPLACE} = <<'_STR_NEWLINE_REPLACE_');

_STR_NEWLINE_REPLACE_

    %conf;

}

1;
