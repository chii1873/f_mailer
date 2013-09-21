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
use vars qw(%CONF %FORM %alt $q $name_list_ref);
use POSIX qw(SEEK_SET);

sub base64 {

    my ($subject, $nofold) = @_;
    my($str, $padding);
    while ($subject =~ /(.{1,45})/gs) {
        $str .= substr(pack('u', $1), 1);
        chop($str);
    }
    $str =~ tr|` -_|AA-Za-z0-9+/|;
    $padding = (3 - length($subject) % 3) % 3;
    $str =~ s/.{$padding}$/'=' x $padding/e if $padding;
    $str =~ s/(.{76})/$1\n/g unless $nofold;
    $str;

}

sub base64_subj {

    my($subject) = @_;
    $subject = base64($subject, 'nofold');
    "=?ISO-2022-JP?B?$subject?=";

}

sub comma {

    my $num = shift;
    1 while $num =~ s/(.*\d)(\d\d\d)/$1,$2/;
    $num or 0;

}

sub data_convert {

    my %form = @_;

    my $code = $CONF{FORM_TMPL_CHARSET} eq "auto"
     ? ($form{GETCODE} ? Unicode::Japanese->new($form{GETCODE})->getcode() : "sjis")
     : $CONF{FORM_TMPL_CHARSET};
use Data::Dumper;
#die (Dumper(\%CONF));
#die $code;

#die($CONF{FORM_TMPL_CHARSET});
    my %form2;
    while (my($key, $value) = each %form) {
        $key = Unicode::Japanese->new($key, $code)->sjis;
        $value = Unicode::Japanese->new($value, $code)->sjis;
        $form2{$key} = $value;
    }
    for (@$name_list_ref) { Unicode::Japanese->new($_, $code)->sjis }
    %form2;
#die (Dumper(\%form2));

}

sub decoding {

    my $q = shift;
    my @name_list;
    my %form;
    my %form_name_cnt;
    foreach my $name($q->param()) {
        foreach my $each($q->param($name)) {
            if (defined($form{$name})) {
                $form{$name} = join('!!!', $form{$name}, $each);
            } else {
                $form{$name} = $each;
            }
        }
        push(@name_list, $name) unless $form_name_cnt{$name}++;
    }
    return \@name_list, %form;

}

sub error_ {

    print "Content-type: text/html; charset=Shift_JIS\n\n";
    print @_;
    exit;

}

sub get_checklist {

    open(R, "data/check.txt")
     or error("data/check.txtが開けませんでした。: $!");
    my @list;
    while (<R>) {
        chomp;
        my($name, $dsp, $flag, $size, $description) = split(/\t/);
        push(@list, { name=>$name, dsp=>$dsp, flag=>$flag, size=>$size, description=>$description });
    }
    @list;

}

sub get_conffile_by_id {

    my $conf_id = shift;
    open(R, "data/conflist.cgi")
     or error_("data/conflist.cgiを開くことができませんでした。: $!");
    while (<R>) {
        my($id, $file, $label) = split(/\t/);
        return $file if $id eq $conf_id;
    }
    error_("指定されたID(=$conf_id)のデータがありませんでした。");

}

sub get_conflist {

    open(R, "data/conflist.cgi")
     or error("data/conflist.cgiを開くことができませんでした。: $!");
    my $conflist;
    my @list;
    while (<R>) {
        chomp;
        my($id, $file, $label) = split(/\t/);
        $conflist .= qq{<option value="$id">$label($id)\n};
        push(@list, { id=>$id, file=>$file, label=>$label});
    }
    return wantarray ? @list : $conflist;

}

sub get_cookie {

    my $cookie_name = shift;
    error('get_cookie: Cookie name must be specified.') if !$cookie_name;
    foreach (split(/; /, $ENV{HTTP_COOKIE})) {
        my($name, $value) = split(/=/);
        if ($name eq $cookie_name) {
            my @cookie_data = split(/\!\!\!/, $value);
            return wantarray ? @cookie_data : $cookie_data[0];
        }
    }
    return undef;

}

sub get_datetime {

    my $time = shift;

    my($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime($time);
    sprintf("%04d-%02d-%02d %02d:%02d:%02d",
     $year+1900,++$mon,$mday,$hour,$min,$sec);

}

sub get_datetime_for_cookie {

    my($time) = @_;
    my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime(time + $time);
    sprintf("%s, %02d-%s-%04d %02d:%02d:%02d GMT",
     (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday],
     $mday, (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon],
     $year+1900, $hour, $min, $sec);

}

sub get_datetime_for_mailheader {

    my $time = shift || time;
    my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime($time + 32400);
    sprintf("%s, %d %s %04d %02d:%02d:%02d +0900",
     (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday],
     $mday, (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon],
     $year+1900, $hour, $min, $sec);

}

sub get_formdatalist {

    my %ignore_name = map { $_ => 1 } reserved_words();
    my $list;
    foreach my $name(@$name_list_ref) {
        next if $ignore_name{$name};
        my $name_dsp = $alt{$name} || $name;
        $list .= <<STR;
<tr><th align=left>$name_dsp</th><td>##$name##</td></tr>
STR
    }

    $list =~ s/##([^#]+)##/replace($1,'html', \%FORM)/eg;
    $list;

}

sub h2z {

     my($str) = @_;
     return Unicode::Japanese->new($str, "sjis")->h2z->sjis;

}

sub h2z_kana {

    my($str) = @_;
    return h2z($str);

}

sub html_output_escape {

    my $str = shift;
    $str =~ s/&/&amp;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/"/&quot;/g;
    $str =~ s/'/&#39;/g;
    $str;

}

sub imgsave {

#    no strict 'subs';
    umask 0;

    my($param) = @_;
    my $filename = $q->param($param);
    my $stream;
    my $temp ||= time . $$;

    if (ref $q->uploadInfo($q->param($param))) {
        my $ctype = $q->uploadInfo($q->param($param))->{'Content-Type'};
        if ($ctype =~ /macbinary/) {
            my $len;
            seek ($q->param($param), 83, SEEK_SET);
            read ($q->param($param), $len, 4);
            $len = unpack "%N", $len;
            seek ($q->param($param), 128, SEEK_SET);
            read ($q->param($param), $stream, $len);
        } else {
            my $buf;
            $stream .= $buf while read($q->param($param),$buf,1024);
        }
    }

    if ($stream) {
        $filename = Unicode::Japanese->new($filename, "sjis")->euc;
        my @path = split(/\\/, $filename);
        $filename = $path[-1];
        $filename = Unicode::Japanese->new($filename, "euc")->sjis;
        (my $filename_enc = $filename) =~ s/([^\da-zA-Z_.,-])/'%'.unpack('H2',$1)/eg;
        (my $filename_enc_clean) = $filename_enc =~ /^([\da-zA-Z_.,%-]+)$/;
        error("taint check error: $filename")
         unless $filename_enc_clean eq $filename_enc;
        open(W, "> ./temp/$temp-$filename_enc_clean")
         or error("Failed to write ./temp/$temp-$filename_enc_clean: $!");
        print W $stream;
        close(W);
        ($temp, $filename, length($stream));
    } else {
        undef;
    }

}

sub load_condcheck {

    my %condcheck;
    $condcheck{compare} = sub {
        my($f_name, $alt_name, $f_value, $cond) = @_;
        my @errmsg;
        if ($f_value ne "" and $cond ne "" and $f_value ne $cond) {
            push(@errmsg, set_errmsg(key=>"compare", f_name=>($alt_name or $f_name)));
        }
        ($f_value, @errmsg);
    };
    $condcheck{d_only} = sub {
        my($f_name, $alt_name, $f_value) = @_;
        my @errmsg;
        if ($f_value =~ /\D/) {
            push(@errmsg, set_errmsg(key=>"d_only", f_name=>($alt_name or $f_name)));
        }
        ($f_value, @errmsg);
    };
    $condcheck{deny_rel} = sub {
        my($f_name, $alt_name, $f_value) = @_;
        my @errmsg;
        my $ret = mojichk($FORM{$f_name}, ($alt_name or $f_name));
        push(@errmsg, $ret) if $ret;
        ($f_value, @errmsg);
    };
    $condcheck{email} = sub {
        my($f_name, $alt_name, $f_value, $cond) = @_;
        my @errmsg;
        if ($f_value and $f_value !~ /^[-_.!*a-zA-Z0-9\/&+%\#]+\@[-_.a-zA-Z0-9]+\.(?:[a-zA-Z]{2,4})$/) {
            push(@errmsg, set_errmsg(key=>"email", f_name=>($alt_name or $f_name)));
        }
        ($f_value, @errmsg);
    };
    $condcheck{h2z} = sub {
        my($f_name, $alt_name, $f_value) = @_;
        return h2z($f_value);
    };
    $condcheck{h2z_kana} = sub {
        my($f_name, $alt_name, $f_value) = @_;
        return h2z_kana($f_value);
    };
    $condcheck{hira2kata} = sub {
        my($f_name, $alt_name, $f_value) = @_;
        return Unicode::Japanese->new($f_value, "sjis")->hira2kata->sjis;
    };
    $condcheck{hira_only} = sub {
        my($f_name, $alt_name, $f_value) = @_;
        my @errmsg;
        unless ($f_value =~ /^(?:\x82[\x9f-\xf1]|\x81[\x40\x4a\x4b\x54\x55])*$/o) {
            push(@errmsg, set_errmsg(key=>"hira_only", f_name=>($alt_name or $f_name)));
        }
        ($f_value, @errmsg);
    };
    $condcheck{kata2hira} = sub {
        my($f_name, $alt_name, $f_value) = @_;
        return Unicode::Japanese->new($f_value, "sjis")->kata2hira->sjis;
    };
    $condcheck{kata_only} = sub {
        my($f_name, $alt_name, $f_value) = @_;
        my @errmsg;
        unless ($f_value =~ /^(?:\x83[\x40-\x96]|\x81[\x40\x45\x5b\x52\x53])*$/o) {
            push(@errmsg, set_errmsg(key=>"kata_only", f_name=>($alt_name or $f_name)));
        }
        ($f_value, @errmsg);
    };
    $condcheck{max} = sub {
        my($f_name, $alt_name, $f_value, $cond, $type, $d_only) = @_;
        my @errmsg;
        if ($d_only) {
            if ($FORM{$f_name} ne '' and $FORM{$f_name} > $cond) {
                push(@errmsg, set_errmsg(key=>"max", f_name=>($alt_name or $f_name), cond=>$cond));
            }
        } elsif ($type eq "select" or $type eq "checkbox") {
            if (scalar(split(/\!\!\!/, $f_value)) > $cond) {
                push(@errmsg, set_errmsg(key=>"num_max", f_name=>($alt_name or $f_name), cond=>$cond));
            }
        } else {
            if (length($f_value) > $cond) {
                push(@errmsg, set_errmsg(key=>"len_max", f_name=>($alt_name or $f_name), cond=>$cond, cond2=>int($cond/2)));
            }
        }
        ($f_value, @errmsg);
    };
    $condcheck{min} = sub {
        my($f_name, $alt_name, $f_value, $cond, $type, $d_only) = @_;
        my @errmsg;
        if ($d_only) {
            if ($f_value ne '' and $f_value < $cond) {
                push(@errmsg, set_errmsg(key=>"min", f_name=>($alt_name or $f_name), cond=>$cond));
            }
        } elsif ($type eq "select" or $type eq "checkbox") {
            if (scalar(split(/\!\!\!/, $f_value)) < $cond) {
                push(@errmsg, set_errmsg(key=>"num_min", f_name=>($alt_name or $f_name), cond=>$cond));
            }
        } else {
            if (length($f_value) < $cond) {
                push(@errmsg, set_errmsg(key=>"len_min", f_name=>($alt_name or $f_name), cond=>$cond));
            }
        }
        ($f_value, @errmsg);
    };
    $condcheck{regex} = sub {
        my($f_name, $alt_name, $f_value, $cond) = @_;
        my @errmsg;
        eval {
            if ($f_value =~ /$cond/) {
                push(@errmsg, set_errmsg(key=>"regex", f_name=>($alt_name or $f_name)));
            }
        };
        push(@errmsg, set_errmsg(key=>"regex_eval_error",
         f_name=>($alt_name or $f_name), eval=>$@)) if $@;
        ($f_value, @errmsg);
    };
    $condcheck{regex2} = sub {
        my($f_name, $alt_name, $f_value, $cond) = @_;
        my @errmsg;
        eval {
            if ($f_value !~ /$cond/) {
                push(@errmsg, set_errmsg(key=>"regex2", f_name=>($alt_name or $f_name)));
            }
        };
        push(@errmsg, set_errmsg(key=>"regex_eval_error",
         f_name=>($alt_name or $f_name), eval=>$@)) if $@;
        ($f_value, @errmsg);
    };
    $condcheck{required} = sub {
        my($f_name, $alt_name, $f_value, $cond, $type) = @_;
        my @errmsg;
        if ($f_value eq '') {
            push(@errmsg, set_errmsg(key=>"required",
             f_name=>($alt_name or $f_name),
             str=>$CONF{errmsg}{$type =~ /^(?:radio|checkbox|select)$/ ? "required_choose" : "required_input" })
            );
        }
        ($f_value, @errmsg);
    };
    $condcheck{trim} = sub {
        my($f_name, $alt_name, $f_value) = @_;
        $f_value =~ s/[\r\n]+//g;
        ($f_value);
    };
    $condcheck{trim2} = sub {
        my($f_name, $alt_name, $f_value) = @_;
        $f_value =~ s/^(?:\s|(?:\x81\x40))+//o;
        $f_value =~ s/^((?:[\x00-\x7f\xa1-\xdf]|(?:[\x81-\x9f\xe0-\xfc][\x40-\x7e\x80-\xfc]))*?)(?:\s|(?:\x81\x40))+$/$1/o;
        ($f_value);
    };
    $condcheck{url} = sub {
        my($f_name, $alt_name, $f_value) = @_;
        my @errmsg;
        if ($f_value and $f_value !~ m#(s?https?://[-_.!~*'()a-zA-Z0-9;/?:\@&=+\$,%\#]+)#) {
            push(@errmsg, set_errmsg(key=>"url", f_name=>($alt_name or $f_name)));
        }
        ($f_value, @errmsg);
    };
    $condcheck{z2h} = sub {
        my($f_name, $alt_name, $f_value) = @_;
        return z2h($f_value);
    };
    open(my $fh, "<", "data/check.txt")
     or error("Failed to open check.txt: $!");
    while (<$fh>) {
        my($f) = split(/\t/, $_, 2);
        push(@{$condcheck{__order}}, $f);
    }
    return %condcheck;

}

sub mojichk {

    my($str, $fname) = @_;
    my @error_char;

    my @chars = $str =~ /[\x20-\x7e\xa1-\xdd][\xde\xdf]*|[\x81-\x9f\xe0-\xfc][\x40-\xfc]/og;

    foreach my $char(@chars) {
        my $code = lc(unpack("H*",$char));
        if (length($char) == 2 and ($code lt '8140' or $code gt '84be' and $code lt '889f' or $code gt '9872' and $code lt '989f' or $code gt 'eaa4')) {
            push(@error_char, $char);
        }
    }

    @error_char
     ? ("$fname の欄の、「" . join("」「", @error_char) .
       "」の文字は、機種依存であるため使用できません。")
     : "";

}

sub printhtml {

    my($filename, %tr) = @_;

    my $charset;
    if (exists $tr{CHARSET}) {
        $charset = $tr{CHARSET};
        delete $tr{CHARSET};
    }
    $charset ||= "auto";

    open(R, "tmpl/_header.html");
    my $header = join("", <R>);
    $header =~ s/##STYLESHEET##/$CONF{STYLESHEET}/g;
    map { $header =~ s/##$_##/$CONF{$_}/g } qw(TEXT BGCOLOR LINK VLINK ALINK BACKGROUND BORDER SYS_TEXT SYS_BGCOLOR SYS_LINK SYS_VLINK SYS_ALINK SYS_BACKGROUND SYS_BORDER);
    close(R);
    open(R, "tmpl/_footer.html");
    my $footer = join("", <R>);
    close(R);
    my($code, $htmlstr) = printhtml_getpage(filename=>$filename,
     charset=>$charset, header=>$header, footer=>$footer);
    foreach my $key(keys %tr) {
        $htmlstr =~ s/##$key##/$tr{$key}/g;
    }
    printhtml_output($code, $htmlstr);

}

sub printhtml_getpage {

    my %opt = @_;
#die Dumper(\%opt);
    ### 2007-7-19 http経由テンプレート読み込み対応
    my $htmlstr;
    if ($opt{filename} =~ /^http/) {
        eval "use LWP::Simple;";
        error_("printhtml: Could not load LWP::Simple module: $@") if $@;
        $htmlstr = get($opt{filename});
    } else {
        open(R, $opt{filename}) or error_("printhtml: Failed to open $opt{filename}: $!");
        $htmlstr = join("", <R>);
        close(R);
    }
    my $code;
    if ($ENV{SCRIPT_FILENAME} =~ m#admin# or $opt{filename} =~ m#\./tmpl/default/#) {
        $opt{charset} = "sjis";
    } else {
        my $code = Unicode::Japanese->new($htmlstr)->getcode() || "sjis";
        $code = "utf8" if $code =~ /utf/;
        $opt{charset} = $code if $opt{charset} eq "auto";
        $htmlstr = Unicode::Japanese->new($htmlstr, $opt{charset})->sjis;
    }
    $htmlstr =~ s/<!-- header -->/$opt{header}/;
    $htmlstr =~ s/<!-- footer -->/$opt{footer}/;
    ######################################################################
    ### 下の処理を変更しないでください。                               ###
    ### 各ページのフッタ部分の著作権表示をなくしたい場合は、届け出の上 ###
    ### 利用規約第10条第5項の料金をお支払いいただきます。              ###
    ### http://www.psl.ne.jp/lab/copyright.html                        ###
    ######################################################################
    $htmlstr =~ s/##COPYRIGHT##/$ENV{SCRIPT_FILENAME} =~ m#admin# ? $CONF{copyright_html_footer_admin} : $CONF{copyright_html_footer}/eg;
#     or error_("$opt{filename}内に ##COPYRIGHT## という指定がありません。:$code:$htmlstr");

    $htmlstr =~ s/##prod_name##/$CONF{prod_name}/g;
    $htmlstr =~ s/##version##/$CONF{version}/g;
    ($opt{charset}, $htmlstr);
}

sub printhtml_output {

    my ($code, $htmlstr) = @_;

    print "Content-type: text/html; charset=";
    if ($code eq "utf8") {
        print "utf-8\n\n", Unicode::Japanese->new($htmlstr, "sjis")->utf8;
    } elsif ($code eq "euc") {
        print "euc-jp\n\n", Unicode::Japanese->new($htmlstr, "sjis")->euc;
    } else {
        print "Shift_JIS\n\n$htmlstr";
    }

}

sub remote_host {

    if ($ENV{REMOTE_HOST} eq $ENV{REMOTE_ADDR} or $ENV{REMOTE_HOST} eq '') {
        gethostbyaddr(pack('C4',split(/\./,$ENV{REMOTE_ADDR})),2)
         or $ENV{REMOTE_ADDR};
    } else {
        $ENV{REMOTE_HOST};
    }
}

sub replace {

    my($fieldstr, $mode, $form_ref) = @_;
    my($fieldname, $indent, $option) = split(/:/, $fieldstr);
    my $V;
    my $value = $form_ref->{$fieldname};
    $value =~ s/\!\!\!/$option eq 'h' ? " " : "\n"/eg;
    $value =~ s/\n/"\n" . ' ' x $indent/eg if $indent;

    if ($mode eq 'html') {
        $value = html_output_escape($value);
        $value =~ s/\n/<br>\n/g;
    }

    $value eq '' ? $CONF{BLANK_STR} : $value;

}

sub reserved_words {

    qw(CONF CONFID TEMP VALUES CREDIT SEND_FORCED GETCODE);
}

sub reserved_words2 {

    reserved_words();
}

sub reserved_words3 {

    ### conf_to_temp()で、@{$CONF{COND}}のリストの内パネルを出力しない
    ### 項目を指定する

    qw(SERIAL REMOTE_HOST REMOTE_ADDR USER_AGENT NOW_DATE);
}

sub sendmail {

    my %opt = @_;

    $opt{envelope} = "-f $opt{envelope}" if $opt{envelope};

    my $subject_enc = Unicode::Japanese->new($opt{subject}, "sjis")->jis;
    $opt{mailstr} = Unicode::Japanese->new($opt{mailstr}, "sjis")->jis;
    $subject_enc = base64_subj($subject_enc) if $subject_enc =~ /[^\t\n\x20-\x7e]/;
    if ($opt{fromname}) {
        $opt{fromname} = Unicode::Japanese->new($opt{fromname}, "sjis")->jis;
        $opt{fromname} = base64_subj($opt{fromname}) if $opt{fromname} =~ /[^\t\n\x20-\x7e]/;
        $opt{fromname} = qq{"$opt{fromname}" <$opt{from}>};
    } else {
        $opt{fromname} = $opt{from};
    }
    my $date = get_datetime_for_mailheader(time);

    open(MAIL, "| $CONF{SENDMAIL} -t $opt{envelope}")
         or error("Failed to open sendmail: $!");
    print MAIL "Date: $date\n";
    print MAIL "To: $opt{mailto}\n";
    print MAIL "From: $opt{fromname}\n";
    print MAIL "Subject: $subject_enc\n";
    print MAIL $opt{mailstr};
    close(MAIL) or error("Failed to send the form.: $!");

}

sub serial_increment {

    my $conf_id = shift;
    ($conf_id) = $conf_id =~ /^(\w+)$/;
    unless (-e "./data/serial/$conf_id") {
        open(W, "> ./data/serial/$conf_id")
         or error("Could not create serial number file: $!");
        close(W);
    }
    open(RW, "+<./data/serial/$conf_id")
     or error("Failed to open serial number file: $!");
    flock(RW, LOCK_EX);
    seek(RW, 0, 0);
    my $serial = <RW> || 0;
    my $length = length($serial);
#error($length,$serial);
    $serial = sprintf("%0${length}d", ++$serial);
#error($serial);
    truncate(RW, 0);
    seek(RW, 0, 0);
    print RW $serial;
    close(RW);

    return $serial;

}

sub set_cookie {

    my($cookie_name, $expire, @cookie_data) = @_;
    my($cookie_data) = join('!!!', @cookie_data);
    $expire = "expires=". get_datetime_for_cookie($expire) . "; "
     if $expire;
    print "Set-Cookie: $cookie_name=$cookie_data; $expire\n";

}

sub set_default_confirm_format {

    my $title = html_output_escape($CONF{TITLE});
    my $default_confirm_format = <<STR;
<html>
<head>
<title>$title</title>
<style>
$CONF{STYLE}
</style>
</head>
<body text="$CONF{TEXT}" bgcolor="$CONF{BGCOLOR}" link="$CONF{LINK}" vlink="$CONF{VLINK}" alink="$CONF{ALINK}" background="$CONF{BACKGROUND}">
<h2>$title</h2>

送信内容を確認します。<br>
内容が正しい場合は<b>送信</b>ボタンを押してください。<br>
訂正する場合は<b>戻る</b>ボタンで前のページへ戻って訂正してください。<p>
<form action=f_mailer.cgi method=post>
<table border cellpadding=3 cellspacing=0>
<tr><th>項　目</th><th>内　容</th></tr>
STR

    my %reserved_words = map { $_ => 1 } reserved_words();
    foreach (@{$CONF{COND}}) {
        my($f_name, $cond_hash) = @$_;
        $reserved_words{"${f_name}2"} = 1 if $cond_hash->{verify};
    }
    foreach my $name(@{$CONF{name_list}}) {
        next if $reserved_words{$name};
        next if $CONF{BLANK_SKIP} and $FORM{$name} eq '';
        my $name_dsp = $alt{$name} || $name;
        $default_confirm_format .= <<STR;
<tr><th>$name_dsp</th><td>##$name##</td></tr>
STR
    }

    $default_confirm_format .= <<STR;
</table><p>
##VALUES##
<input type=submit value=送　信>
<input type=button value=戻　る onclick=history.back()>
</form>
$CONF{copyright_html_footer}
</body></html>
STR

    $default_confirm_format;

}

sub set_default_mail_format {

    my %opt = @_;
    my($mark, $sepr, $oft) = $opt{reply}
     ? @CONF{qw(REPLY_MARK REPLY_SEPR REPLY_OFT)}
     : @CONF{qw(MARK SEPR OFT)};

    my $default_mail_format = <<STR;
------------------------------------------------------------
$CONF{TITLE}
------------------------------------------------------------
STR

    my $indent = (" " x length($mark));
    my %skip = map { $_ => 1 } reserved_words();
    foreach my $name(@$name_list_ref) {
        next if $CONF{BLANK_SKIP} and $FORM{$name} eq '';
        next if $skip{$name};
        my $name_dsp = $alt{$name} || $name;
        my $value_dsp = $FORM{$name};

        if ($opt{type} == 1) {
            $value_dsp =~ s/\!\!\!|\n/\n$indent/g;
            $default_mail_format .= "$mark$name_dsp$sepr\n$indent$value_dsp\n\n";
        } elsif ($opt{type} == 2) {
            $value_dsp =~ s/\!\!\!/ /g;
            $value_dsp =~ s/\n/\n$indent/g;
            $default_mail_format .= "$mark$name_dsp$sepr$value_dsp\n";
        } else {
            $value_dsp =~ s/\!\!\!/ /g;
            $value_dsp =~ s/\n/"\n".(" " x ($oft+length($sepr)))/eg;
            $default_mail_format .= sprintf("%-${oft}s","$mark$name_dsp").
                                    "$sepr$value_dsp\n";
        }
    }

    $default_mail_format .= <<STR;
------------------------------------------------------------
送信日時    ：$FORM{NOW_DATE}
接続元ホスト：$FORM{REMOTE_HOST}
使用ブラウザ：$FORM{USER_AGENT}
------------------------------------------------------------
STR

    $default_mail_format;

}

sub set_errmsg {

    my %opt = @_;
    my $str = $CONF{errmsg}{$opt{key}};
    $opt{str} =~ s/##f_name##/$opt{f_name}/g;
    $str =~ s/##$_##/$opt{$_}/g for qw(f_name cond cond2 eval str);
    return $str;

}

sub set_errmsg_init {

    ### 2008-6-12 暫定的にこの位置に指定
    ### 管理画面で設定できるようにする
    $CONF{errmsg} = {
	# ##f_name##…フィールド名
	# ##cond##…min/max条件で、上限あるいは下限値
	# ##eval##…regex/regex2条件で、evalに失敗したときに返される$@の値
	# ##str##…required条件で、
	#           radio/checkbox/selectは「required_choose」
	#           その他は「required_input」
	compare  => q|##f_name##が一致しません。|,
	d_only   => q|##f_name##は半角数字で入力してください。|,
#	deny_rel => q|##f_name##を正しく入力してください。|,
	email    => q|##f_name##を正しく入力してください。|,
	hira_only=> q|##f_name##は全角ひらがなで入力してください。|,
	kata_only=> q|##f_name##は全角カタカナで入力してください。|,
#	len_max  => q|##f_name##は##cond##文字(半角)以下で入力してください。|,
	len_max  => q|##f_name##は##cond2##文字(全角)以下で入力してください。|,
	num_max  => q|##f_name##のチェックは##cond##個以下にしてください。|,
	max      => q|##f_name##は##cond##以下の数値を入力してください。|,
	len_min  => q|##f_name##は##cond##文字(半角)以上で入力してください。|,
	num_min  => q|##f_name##のチェックは##cond##個以上にしてください。|,
	min      => q|##f_name##は##cond##以上の数値を入力してください。|,
	regex    => q|##f_name##を正しく入力してください。|,
	regex2   => q|##f_name##を正しく入力してください。|,
	regex_eval_error => q|##f_name##の正規表現が不正です。:##eval##|,
	required => q|##f_name##を##str##してください。|,
	required_choose => q|選択|,
	required_input  => q|入力|,
	url      => q|##f_name##を正しく入力してください。|,
    };

}

sub setalt {

    my %alt;
    foreach (@{$CONF{COND}}) { $alt{$_->[0]} = $_->[1]->{alt}; }
    return %alt;
}

sub setver {
##############################################
###このサブルーチンは変更しないでください。###
##############################################
    my %PROD = (
        prod_name => q{FORM MAILER},
        version   => q{0.63},
        a_email   => q{info@psl.ne.jp},
        a_url     => q{http://www.psl.ne.jp/},
        copyright => q{&copy;1997-2008},
        copyright2 => q{(c)1997-2008},
    );
    chomp($PROD{copyright_html_footer} = <<STR);
&nbsp;
STR
    chomp($PROD{copyright_html_footer_admin} = <<STR);
&copy;
STR

    chomp($PROD{copyright_mail_footer} = <<STR);
STR
##############################################
###              ここまで                  ###
##############################################
    return %PROD;

}

sub temp_del {

    my $hours = shift;

    my $now = time;
    opendir(DIR, "temp")
     or error("Could not open temp directory: $!");
    foreach my $file(grep(!/^\.\.?/, readdir(DIR))) {
        ($file) = $file =~ /^(\d+.*)$/;
        unlink("temp/$file") if (stat("temp/$file"))[10] < $now - $hours * 3600;
    }

}

sub temp_read {

    my($page, $temp) = @_;
    open(R, "temp/$temp-$page")
#     or error("temp/$temp-$pageを開けませんでした。: $!");
    ;
    my %form;
    while (<R>) {
        chomp;
        my($k, $v) = split(/:/, $_, 2);
        $v =~ s/\x0b/\n/g;
        $form{$k} = $v;
        for my $v_(split(/\!\!\!/, $v)) {
            $form{"$k\0$v_"} = $v_;
        }
    }
    close(R);

    return %form;

}

sub temp_write {

    my($page, %form) = @_;
    my $temp = $ENV{SCRIPT_FILENAME} =~ /admin/ ? "temp" : "TEMP";
    $form{$temp} ||= time . $$;

    ($form{$temp}) = $form{$temp} =~ /^(\d+)$/;
#    ($page) = $page =~ /^(\w+)$/;
    open(W, "> temp/$form{$temp}-$page")
     or error("Failed to write temp/$form{$temp}-$page: $!");
    foreach ($page eq "confform" ? ("label", get_conffields()) : keys %form) {
        $form{$_} =~ s/\r?\n/\x0b/g;
        print W "$_:$form{$_}\n";
    }
    close(W);

    return $form{$temp};

}

sub uuencode {

    my($str, $filename) = @_;
    $str = pack('u', $str);
    $str = "begin 644 $filename\n$str\`\nend";
    $str;

}

sub z2h {

     my($str) = @_;
     return Unicode::Japanese->new($str, "sjis")->z2h->h2zKana->sjis;

}

1;
