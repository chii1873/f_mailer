# ---------------------------------------------------------------
#  - システム名    フォームデコード+メール送信 (FORM MAILER)
#  - バージョン    0.62
#  - 公開年月日    2007/10/9
#  - スクリプト名  f_mailer_lib.pl
#  - 著作権表示    (c)1997-2007 Perl Script Laboratory
#  - 連  絡  先    http://www.psl.ne.jp/bbpro/
#                  https://awawa.jp/psl/lab/pslform.html
# ---------------------------------------------------------------
# ご利用にあたっての注意
#   ※このシステムはフリーウエアです。
#   ※このシステムは、「利用規約」をお読みの上ご利用ください。
#     http://www.psl.ne.jp/lab/copyright.html
# ---------------------------------------------------------------
use strict;
use vars qw(%CONF $smtp);

sub sendmail {

    eval qq{use Net::SMTP};
    error_("Net::SMTPがインストールされていません。: $@") if $@;
    if ($CONF{USE_SMTP_AUTH}) {
        eval qq{use MIME::Base64};
        error_("MIME::Base64がインストールされていません。: $@") if $@;
        eval qq{use Authen::SASL};
        error_("Authen::SASLがインストールされていません。: $@") if $@;
    }

    my %opt = @_;

    my $subject_enc = $opt{subject};
    $opt{mailstr} = Unicode::Japanese->new($opt{mailstr}, "sjis")->jis;
    $subject_enc = base64_subj($subject_enc) if $subject_enc =~ /[^\t\n\x20-\x7e]/;
    $subject_enc = base64_subj($subject_enc) if $subject_enc =~ /[^\t\n\x20-\x7e]/;
    if ($opt{fromname}) {
        $opt{fromname} = Unicode::Japanese->new($opt{fromname}, "sjis")->jis;
        $opt{fromname} = base64_subj($opt{fromname}) if $opt{fromname} =~ /[^\t\n\x20-\x7e]/;
        $opt{fromname} = qq{"$opt{fromname}" <$opt{from}>};
    } else {
        $opt{fromname} = $opt{from};
    }

    $smtp ||= Net::SMTP->new($CONF{SMTP_HOST})
     or error("Net::SMTPで$CONF{SMTP_HOST}へ接続できませんでした。: $!");
    my $date = get_datetime_for_mailheader(time);

    if ($CONF{USE_SMTP_AUTH}) {
        $smtp->auth($CONF{SMTP_AUTH_ID}, $CONF{SMTP_AUTH_PASSWD})
         or do { $smtp->quit; error('authメソッド失敗: ' .$!); };
    }
    $smtp->mail($opt{envelope} || $opt{from});
    $smtp->to($opt{mailto});
    $smtp->data();
    $smtp->datasend("Date: $date\n");
    $smtp->datasend("To: $opt{mailto}\n");
    $smtp->datasend("From: $opt{fromname}\n");
    $smtp->datasend("Subject: $subject_enc\n");
    $smtp->datasend($opt{mailstr});
    $smtp->dataend();
#    $smtp->quit;

}

1;
