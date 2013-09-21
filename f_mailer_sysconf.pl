#
# FORM MAILER v0.63 設定ファイル
# (c)1997-2013 Perl Script Laboratory All rights reserved.
#
# f_mailer_sysconf.pl
#
# このファイルはプログラムによって自動生成されました。
# 生成日時: 2013-05-07 22:32:40

package conf;

 sub sysconf {

    my %conf;

    chomp($conf{LANG_DEFAULT} = <<_STR_LANG_DEFAULT_);
ja
_STR_LANG_DEFAULT_
    chomp($conf{SENDMAIL_FLAG} = <<_STR_SENDMAIL_FLAG_);
1
_STR_SENDMAIL_FLAG_
    chomp($conf{SENDMAIL} = <<_STR_SENDMAIL_);
/usr/sbin/sendmail
_STR_SENDMAIL_
    chomp($conf{SMTP_HOST} = <<_STR_SMTP_HOST_);
localhost
_STR_SMTP_HOST_
    chomp($conf{ALLOW_FROM} = <<_STR_ALLOW_FROM_);
110.4.189.181
_STR_ALLOW_FROM_

    %conf;

}

1;
