#!/usr/bin/perl
### for dedug
#!/usr/bin/perl -Tw
# ---------------------------------------------------------------
#  - システム名    フォームデコード+メール送信 (FORM MAILER)
#  - バージョン    0.63
#  - 公開年月日    2013/05/01
#  - スクリプト名  f_mailer.cgi
#  - 著作権表示    (c)1997-2013 Perl Script Laboratory
#  - 連  絡  先    http://www.psl.ne.jp/bbpro/
#                  https://awawa.jp/psl/lab/pslform.html
# ---------------------------------------------------------------
# ご利用にあたっての注意
#   ※このシステムはフリーウエアです。
#   ※このシステムは、「利用規約」をお読みの上ご利用ください。
#     http://www.psl.ne.jp/lab/copyright.html
# ---------------------------------------------------------------
use strict;
use lib qw(./lib);
use vars qw($q %FORM %CONF $name_list_ref %alt $conffile %ERRMSG);
#use utf8;
use Encode;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Unicode::Japanese;
use Fcntl ':flock';
use String::Util qw(trim);

#BEGIN{ print "Content-type: text/html\n\n"; $| =1; open(STDERR, ">&STDOUT"); }

### for dedug
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;
sub d { die Dumper @_ }
#error_(Dumper($CONF{COND}));

require "./f_mailer_lib.pl";
require "./f_mailer_sysconf.pl";
$q = new CGI;
$ENV{PATH} = "/usr/bin:/usr/sbin:/usr/local/bin:/bin";
%CONF = (setver(), conf::sysconf());
#d(\%CONF);
set_errmsg_init();
umask 0;

($name_list_ref, %FORM) = decoding($q);
error_(get_errmsg("000")) unless keys %FORM;

### 設定ファイルのロード
if ($FORM{CONFID}) {
    $conffile = get_conffile_by_id($FORM{CONFID});
    ($conffile) = $conffile =~ /^(.*\.pl)$/;
    eval { require "./data/conf/$conffile"; };
    error_(get_errmsg("001", $@)) if $@;
    if (-e "./data/confext/ext_$conffile") {
        eval { require "./data/confext/ext_$conffile"; };
        error_(get_errmsg("002", $@)) if $@;
    }
} else {
    error_(get_errmsg("003"));
}

### 拡張ファイルのロード
my %conflist = map { $_->{id} => $_->{file} } get_conflist();
if (-e "./data/confext/ext_$conflist{$FORM{CONFID}}") {
    $CONF{EXTFILE_EXIST} = 1;
    eval qq|require "./data/confext/ext_$conflist{$FORM{CONFID}}";|;
	error(get_errmsg("004", $@, $conflist{$FORM{CONFID}})) if $@;
}

%CONF = (%CONF, conf::conf());
set_errmsg_init(); ### フォームの使用言語確定後ロード
%FORM = data_convert(%FORM);
$FORM{REMOTE_HOST} = remote_host();
$FORM{REMOTE_ADDR} = $ENV{REMOTE_ADDR};
$FORM{USER_AGENT}  = $ENV{HTTP_USER_AGENT};
$FORM{NOW_DATE}    = get_datetime(time);

%alt = setalt();

temp_del(2);  ### 2時間経過したtempファイルを削除

if ($FORM{FORM}) {
    %FORM = (%FORM, temp_read("formdata", $FORM{TEMP}));
    form();
}
$FORM{TEMP} = temp_write("formdata", %FORM)
 if !$FORM{TEMP} or !$FORM{SEND_FORCED};
sendmail_do() if ($FORM{SEND_FORCED} or !$CONF{CONFIRM_FLAG} and !$FORM{CONFIRM_FORCED});
checkvalues();
checkuploads();
confirm();

sub checkuploads {

    my %fsize;
    my $fsize;
    my @msg;
    my %ext = map { $_ => 1 } @{$CONF{ATTACH_EXT}};

    foreach my $fname(@{$CONF{ATTACH_FIELDNAME}}) {
        next if $FORM{$fname} eq "";
        my $ext = (split(/\./, $FORM{$fname}))[-1];
        my $filename = (split(/[\\\/]/, $FORM{$fname}))[-1];
#error($fname, $FORM{$fname}, $ext, $filename);
        unless ($ext{$ext}) {
            push(@msg, get_errmsg("100", ($alt{$fname} or $fname), $filename));
            next;
        }
        (my $temp, $FORM{$fname},$fsize{$fname}) = imgsave($fname);
        $FORM{TEMP} ||= $temp;
        if ($CONF{ATTACH_SIZE_MAX} and $fsize{$fname} > $CONF{ATTACH_SIZE_MAX} * 1024) {
            push(@msg, get_errmsg("101", $FORM{$fname}, $CONF{ATTACH_SIZE_MAX}));
        }
        $fsize += $fsize{$fname};
    }
    if ($CONF{ATTACH_TSIZE_MAX} and $fsize > $CONF{ATTACH_TSIZE_MAX} * 1024) {
        push(@msg, get_errmsg("102", $CONF{ATTACH_TSIZE_MAX}));
    }
    if (@msg) {
        opendir(DIR, "./temp")
         or error( get_errmsg("103", $!));
        foreach my $f(grep(/^$FORM{TEMP}-/, readdir(DIR))) {
            ($f) = $f =~ /^([\da-zA-Z_.,%-]+)$/;
            unlink("./temp/$f");
        }
        error(@msg);
    }

}

sub checkvalues {

    my @errmsg;
    my %condcheck = load_condcheck();
    my @checklist = map { $_->{name} } get_checklist();
    my %to_delete;

    ### フィールドのグループ化
    ### 暫定的にこの位置に入れる
    ext_sub0() if $CONF{EXTFILE_EXIST};
#use Data::Dumper;
#die Dumper \%condcheck;
#die(@{$condcheck{__order}});
    my %group_flag;
    my %cond_hash = map { $_->[0]=>$_->[1] } @{$CONF{COND}};
    foreach (@{$CONF{COND}}) {
        my($f_name, $cond_hash) = @$_;

        if ($CONF{field_group_rev}{$f_name}) {
            my @group_errmsg;
            my %errtype;
            next if $group_flag{$CONF{field_group_rev}{$f_name}}++;
            for my $group_field(@{$CONF{field_group}{$CONF{field_group_rev}{$f_name}}{list}}) {
                my($errmsg_ref, $to_delete_ref, $errtype_ref)
                 = checkvalues_condcheck(\%condcheck, $group_field, $cond_hash{$group_field}, group=>1);
                %errtype = (%errtype, %$errtype_ref);
                push(@group_errmsg, @$errmsg_ref) if @$errmsg_ref;
            }
            for my $key(grep { $errtype{$_} } @checklist) {
                push(@errmsg, set_errmsg(key=>$key,
                 f_name=>$CONF{field_group}{$CONF{field_group_rev}{$f_name}}{alt},
                 str=>$CONF{errmsg}{required_input},
                ));
            }
            push(@errmsg, @group_errmsg) if @group_errmsg;
        } else {
            my($errmsg_ref, $to_delete_ref)
             = checkvalues_condcheck(\%condcheck, $f_name, $cond_hash);
            %to_delete = (%to_delete, %$to_delete_ref);
            push(@errmsg, @$errmsg_ref) if @$errmsg_ref;
        }
    }

    ### 拡張コードの実行
    ### エラーメッセージのリストを受け取ります。
    if ($CONF{EXTFILE_EXIST}) {
        my @xerrmsg = ext_sub();
        if (ref($xerrmsg[0])) {
            @xerrmsg = @{$xerrmsg[0]};
        }
        push(@errmsg, @xerrmsg) if @xerrmsg;
    }

    error_formcheck(@errmsg) if @errmsg;

    ### グループ指定した元のフィールドを削除
    ### 代わりにグループ指定したフィールドを追加
    ### グループ内で連結した文字列を生成

    my @name_list_new;
    %group_flag = ();
    foreach (keys %to_delete) { delete $FORM{"${_}2"} }
    for (@$name_list_ref) {
        next if /^(.*)2$/ and $to_delete{$1};
        if ($CONF{field_group_rev}{$_}) {
            next if $group_flag{$CONF{field_group_rev}{$_}}++;
            push(@name_list_new, $CONF{field_group_rev}{$_});
            my $vchk = 0;
            for (@{$CONF{field_group}{$CONF{field_group_rev}{$_}}{list}}) {
                $vchk++ if $_ ne "";
            }
            $FORM{$CONF{field_group_rev}{$_}}
             = join($CONF{field_group}{$CONF{field_group_rev}{$_}}{constr},
              @FORM{@{$CONF{field_group}{$CONF{field_group_rev}{$_}}{list}}})
             if $vchk;
            $alt{$CONF{field_group_rev}{$_}} = $CONF{field_group}{$CONF{field_group_rev}{$_}}{alt};
            next;
        }
        push(@name_list_new, $_);
    }
    $name_list_ref = \@name_list_new;
#use Data::Dumper;
#die Dumper $name_list_ref;

    $FORM{TEMP} = temp_write("formdata", %FORM, temp=>$FORM{TEMP},
     FIELDLIST=>join(",", @$name_list_ref),
    );

}

sub checkvalues_condcheck {

    my($condcheck, $f_name, $cond_hash, %opt) = @_;
    my @errmsg;
    my %errtype;
    my %to_delete;

#die($cond_hash);
#    foreach my $key(keys %$cond_hash) {
    foreach my $key(@{$condcheck->{__order}}) {
        next if $key eq 'alt' or $key eq 'attach' or $key eq 'type';
        next unless $cond_hash->{$key};
        $to_delete{$f_name} = $f_name."2" if $key eq "compare";
        ($FORM{$f_name}, my @errmsg_) = &{$condcheck->{$key}}(
         $f_name,
         $alt{$f_name},
         $FORM{$f_name},
         ($key eq "compare" ? $FORM{"${f_name}2"} : $cond_hash->{$key}),
         $cond_hash->{type},
         $cond_hash->{d_only},
        );
        if (@errmsg_) {
            if ($opt{group} and $key !~ /^(?:min|max)$/) {
                $errtype{$key} = 1;
            } else {
                push(@errmsg, @errmsg_);
            }
        }
    }
    $to_delete{$f_name} = 1 if $opt{group};
    return \@errmsg, \%to_delete, \%errtype;

}

sub confirm {

    output_form("CONFIRM") if $CONF{CONFIRM_FLAG} == 2;

#die $FORM{addr};
    printhtml("./tmpl/default/@{[ $CONF{LANG} or $CONF{LANG_DEFAULT} ]}/confirm.html",
     CHARSET=>"sjis",
     list => get_formdatalist(), CONFID=>$FORM{CONFID},
     TEMP=>$FORM{TEMP}, (map { $_ => $CONF{$_} } keys %CONF),
     map { $_ => replace($_, "html", \%FORM) } map { $_->[0] } @{$CONF{COND}});
    exit;

}

sub error {

    my $errmsg = mk_errmsg(\@_);

    output_form("ERROR", $errmsg) if $CONF{ERROR_FLAG};

    printhtml("./tmpl/default/@{[ $CONF{LANG} or $CONF{LANG_DEFAULT} ]}/error.html",
     CHARSET=>"sjis",
     (map { $_ => $CONF{$_} } keys %CONF),
     errmsg => $errmsg,
    );
     exit;

}

sub error_formcheck {

    error(@_) unless $CONF{FORM_FLAG};

    output_form("FORM", \@_);

}

sub form {

    output_form("FORM");

}

sub output_form {

    require "./f_mailer_get_output_form.pl";

    my($phase, $errmsg_ref) = @_;
#die "$phase,$errmsg," , caller();
#d(mk_errmsg($errmsg_ref));

    my($code, $htmlstr) = printhtml_getpage(
     ($CONF{"${phase}_TMPL_CHARSET"} || "auto"),
     {
       filename => $CONF{"${phase}_TMPL"},
       errmsg => ($errmsg_ref || []),
     }
    );

    my %d;
    if (ref $errmsg_ref) {
        %d = temp_read("formdata", $FORM{TEMP});
        $htmlstr =~ s|<!--\s*errmsg\s*-->|mk_errmsg($errmsg_ref)|ie;
        $htmlstr =~ s|##errmsg##|mk_errmsg($errmsg_ref)|ie;
    } else {
        %d = %FORM;
    }
#d(\%d);
    $htmlstr =~ s/##list##/get_formdatalist()/e;
    $htmlstr = get_output_form($phase, $htmlstr, %d, TEMP=>$FORM{TEMP});
    foreach my $key(keys %d) {
        eval { $htmlstr =~ s/##\Q$key\E##/($phase eq "CONFIRM" or $phase eq "THANKS") ? replace($key,'html',\%d) : $d{$key}/eg; };
        error_("$key, $d{$key}, $@") if $@;
    }
    printhtml_output($code, $htmlstr);
    exit;

}

sub sendmail_do {

    my @errmsg;

    if ($CONF{DENY_DUPL_SEND}) {
        if (get_cookie($FORM{CONFID})) {
            error(get_errmsg("110"));
        }
    }

    %FORM = (%FORM, temp_read("formdata", $FORM{TEMP}));
    $name_list_ref = [split(/,/, $FORM{FIELDLIST})];

    ### 拡張コードの実行
    ### エラーメッセージのリストを受け取ります。
    if ($CONF{EXTFILE_EXIST}) {
        my @xerrmsg = ext_sub2();
        if (ref($xerrmsg[0])) {
            @xerrmsg = @{$xerrmsg[0]};
        }
        push(@errmsg, @xerrmsg) if @xerrmsg;
    }

    error(@errmsg) if @errmsg;

    ### シリアル番号の取得
    $FORM{SERIAL} = serial_increment($FORM{CONFID});

    ### フォーム内容メールの送信処理
    unless ($CONF{DO_NOT_SEND}) {
        my($del_list_ref, %attachdata) = sendmail_get_attachdata();
        my $format = $CONF{MAIL_FORMAT_TYPE}
         ? set_default_mail_format(type=>$CONF{MAIL_FORMAT_TYPE})
         : $CONF{FORMAT};
        $format =~ s/##([^#]+)##/replace($1,"",\%FORM)/eg;
        ### 2007-8-4 タイトルにもフォーム埋め込み可能とする
        my $subject = $CONF{SUBJECT};
        $subject =~ s/##([^#]+)##/replace($1,"",\%FORM)/eg;
        my($str, $charset) = sendmail_mkstr(
            str => $format, credit => $CONF{copyright_mail_footer},
            charset=>"",
            attachdata => \%attachdata,
        );
        ### 2007-10-7 エンベロープアドレス対応
        my $envelope = $CONF{ENVELOPE_ADDR_LINK}
         ? ($FORM{EMAIL} || $CONF{SENDFROM}) : $CONF{ENVELOPE_ADDR};
        foreach my $mailto(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/,$CONF{SENDTO})) {
            sendmail(
                charset  => $charset,
                mailto   => $mailto,
                cc       => $CONF{CC},
#                bcc      => $CONF{BCC},
                from     => ($FORM{EMAIL} || $CONF{SENDFROM}),
                subject  => $subject,
                mailstr  => $str,
                fromname => "",
                envelope => $envelope,
            );
        }
    }

    ### 自動返信メールの送信処理
    if ($CONF{AUTO_REPLY}) {
        my $format = $CONF{REPLY_MAIL_FORMAT_TYPE}
         ? set_default_mail_format(type=>$CONF{REPLY_MAIL_FORMAT_TYPE},reply=>1)
         : $CONF{REPLY_FORMAT};
        $format =~ s/##([^#]+)##/replace($1,"",\%FORM)/eg;
        ### 2007-8-4 タイトルにもフォーム埋め込み可能とする
        my $subject = $CONF{REPLY_SUBJECT};
        $subject =~ s/##([^#]+)##/replace($1,"",\%FORM)/eg;
        my($str, $charset) = sendmail_mkstr(
            str => $format, credit => $CONF{copyright_mail_footer},
            charset=>"",
            attachdata => {},
        );
        ### フォーム内容メールの送信処理
        foreach my $mailto(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/,$FORM{EMAIL})) {
            sendmail(
                charset  => $charset,
                mailto   => $mailto,
                cc       => $CONF{REPLY_CC},
#                bcc      => $CONF{REPLY_BCC},
                from     => $CONF{REPLY_SENDFROM},
                subject  => $subject,
                mailstr  => $str,
                fromname => $CONF{REPLY_SENDFROMNAME},
                envelope => $CONF{REPLY_ENVELOPE_ADDR},
            );
        }
    }

    ### ファイル書き出し処理
    sendmail_file_output() if $CONF{FILE_OUTPUT};

    set_cookie($FORM{CONFID}, $CONF{DENY_DUPL_SEND_MIN}, 1)
     if $CONF{DENY_DUPL_SEND};

    if (!$CONF{THANKS_FLAG}) {
        print "Location: $CONF{THANKS}\n\n";
    } else {
        $CONF{SUBJECT} = html_output_escape($CONF{SUBJECT});

        output_form("THANKS") if $CONF{THANKS_FLAG} == 2;

        my $str;
        printhtml("./tmpl/default/@{[ $CONF{LANG} or $CONF{LANG_DEFAULT} ]}/thanks.html",
         CHARSET=>($CONF{THANKS_TMPL_CHARSET} || "auto"),
         (map { $_ => $CONF{$_} } keys %CONF),
         list=>get_formdatalist(),
         map { $_ => replace($_,"html",\%FORM) } map { $_->[0] } @{$CONF{COND}});
    }
    exit;

}

sub sendmail_file_output {

    return unless @{$CONF{OUTPUT_FIELDS}};

    $CONF{OUTPUT_FILENAME} =~ s/##([^#]+)##/$FORM{$1}/g;
    $CONF{OUTPUT_FILENAME} =~ s#([^\da-zA-Z_.,-])#'%' . unpack('H2', $1)#eg;
    unless (-d "data/output/$FORM{CONFID}") {
        mkdir("data/output/$FORM{CONFID}", 0777)
         or error(get_errmsg("116", $CONF{"OUTPUT_FILENAME"}, $!));
    }
    open(my $fh, ">>", qq|./data/$FORM{"CONFID"}/$CONF{"OUTPUT_FILENAME"}|)
     or error(get_errmsg("115", $CONF{"OUTPUT_FILENAME"}, $!));
    flock($fh, LOCK_EX);
    seek($fh, 0, 2);

    my %FORM2;
    foreach my $field(@{$CONF{OUTPUT_FIELDS}}) {
        $FORM{$field} =~ s/\r\n/\n/g;
        $FORM{$field} =~ s/\r/\n/g;
        if ($CONF{OUTPUT_SEPARATOR}) {
            $FORM{$field} =~ s/"/""/g;
            $FORM2{$field} = qq|"$FORM{$field}"|;
            $FORM2{$field} =~ s/\n/$CONF{NEWLINE_REPLACE} eq '' ? "\n" : $CONF{NEWLINE_REPLACE}/eg;
        } else {
            $FORM{$field} =~ s/\t+/ /g;
            $FORM2{$field} = $FORM{$field};
            $FORM2{$field} =~ s/\n/$CONF{NEWLINE_REPLACE}/g;
        }
        $FORM2{$field} =~ s/\!\!\!/$CONF{FIELD_SEPARATOR} eq '' ? " " : $CONF{FIELD_SEPARATOR}/eg;
    }
    print $fh join(($CONF{OUTPUT_SEPARATOR} ? "," : "\t"),
     @FORM2{@{$CONF{OUTPUT_FIELDS}}}),"\n";
    close($fh);

}

sub sendmail_get_attachdata {

    my %attachdata;
    my @del_list;
    if (@{$CONF{ATTACH_FIELDNAME}}) {
        opendir(DIR, "./temp")
         or error(get_errmsg("120", $!));
        foreach my $f_(grep(/^$FORM{TEMP}-/, readdir(DIR))) {
            next if $f_ eq "$FORM{TEMP}-formdata";
            (my $file = $f_)
             =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
            $file =~ s/^$FORM{TEMP}-//;
            open(R, "./temp/$f_")
             or error(get_errmsg("121", $!));
            $attachdata{$file} = join("", <R>);
            close(R);
            ($f_) = $f_ =~ /^([\da-zA-Z_.,%-]+)$/;
            push(@del_list, "./temp/$f_");
        }
        close(DIR);
    }

    return \@del_list, %attachdata;

}

#sub uri_escape {
#
#    my $str = shift;
#    $str =~ s/(\W)/'%' . unpack('H2', $1)/eg;
#    return $str;
#
#}

sub sendmail_mkstr {

    my %opt = @_;
    my $str;
    my $boundary = "--".join("", map { ('0'..'9','a'..'f')[rand(16)] } 1..24);

    if ($opt{charset} eq "UTF-8" or mojichk($opt{str}) or mojichk($opt{credit})) {
        $opt{charset} = "UTF-8";
        # utf-8のまま
    } elsif (! is_ascii($opt{str}) or is_ascii($opt{credit})) {
        $opt{charset} = "ISO-2022-JP";
        $opt{str} = Unicode::Japanese->new($opt{str}, "utf8")->jis;
        $opt{credit} = Unicode::Japanese->new($opt{credit}, "utf8")->jis;
    }

    if (keys %{$opt{attachdata}}) {
        $str .= <<STR;
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="$boundary"


--$boundary
Content-type: text/plain; charset=$opt{charset}

$opt{str}
$opt{credit}
STR
    } else {
        $str .= <<STR;
MIME-Version: 1.0
Content-Transfer-Encording: 7bit
Content-type: text/plain; charset=$opt{charset}

$opt{str}
$opt{credit}
STR
    }

    foreach my $filename(keys %{$opt{attachdata}}) {
#        my $content_type = $filename =~ /\.html?$/ ? "text/html" : "application/octet-stream";
        my $content_type = "application/octet-stream";
        my $encoding_type = $opt{encoding} eq 'uuencode'
         ? "X-uuencode" : "base64";
        my $attachdata = $opt{encoding} eq 'uuencode'
         ? uuencode($opt{attachdata}->{$filename}, $filename)
         : base64($opt{attachdata}->{$filename});
        $str .= <<STR;
--$boundary
Content-Type: $content_type; name="$filename"
Content-Disposition: attachment;
 filename="$filename"
Content-Transfer-Encoding: $encoding_type

$attachdata
STR
    }

    $str .= "--$boundary--\n" if keys %{$opt{attachdata}};

    return ($str, $opt{charset});

}

