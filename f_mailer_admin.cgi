#!/usr/bin/perl
### for dedug
#!/usr/bin/perl -Tw
# ---------------------------------------------------------------
#  - システム名    FORM MAILER 管理ツール
#  - バージョン    0.62
#  - 公開年月日    2007/10/9
#  - スクリプト名  f_mailer_admin.cgi
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
use lib qw(./lib);
use vars qw($q %FORM %CONF %alt $name_list_ref);
use utf8;
use CGI;
use Unicode::Japanese;
#use Jcode;
### for dedug
use CGI::Carp qw(fatalsToBrowser);
use HTML::SimpleParse;
use LWP::Simple;
use Data::Dump;
use JSON;
sub d { die Dumper($_[0]) }
use Fcntl ':flock';
$ENV{PATH} = "/usr/bin:/usr/sbin:/usr/local/bin:/bin";
require './f_mailer_lib.pl';
require './f_mailer_lib_admin.pl';
require './f_mailer_sysconf.pl';
%CONF = (setver(), conf::sysconf());
if ($CONF{SENDMAIL_FLAG}) {
    require './f_mailer_lib_smtp.pl';
}

umask 0;
$CONF{ERROR_TMPL} = "tmpl/error.html";

$q = new CGI;
($name_list_ref, %FORM) = decoding($q);

login() if $FORM{login};
login_form() unless get_cookie("FORM_MAILER_ADMIN");
logout() if $FORM{logout};
chpasswd() if $FORM{chpasswd};
chpasswd_done() if $FORM{chpasswd_done};
confform() if $FORM{confform};
confform_done() if $FORM{confform_done};
confform_select() if $FORM{confform_select};
confpanel() if $FORM{confpanel};
confpanel_import() if $FORM{confpanel_import};
confpanel_import_done() if $FORM{confpanel_import_done};
confserial() if $FORM{confserial};
confserial_done() if $FORM{confserial_done};
del() if $FORM{del};
sysconfform() if $FORM{sysconfform};
sysconfform_done() if $FORM{sysconfform_done};
menu();

sub chpasswd {

    printhtml("tmpl/admin_chpasswd.html");
    exit;

}

sub chpasswd_done {

    $FORM{passwd} or error("新しいパスワードを入力してください。");
    if ($FORM{passwd} ne $FORM{passwd2}) {
        error("確認用パスワードが一致しません。");
    }

    passwd_write($FORM{passwd});

    set_cookie("FORM_MAILER_ADMIN_CACHE", 30, $FORM{passwd})
    if get_cookie("FORM_MAILER_ADMIN_CACHE");
    printhtml("tmpl/admin_chpasswd_done.html");
    exit;

}

sub confform {

    my $errmsg_ref = shift || [];

    if ($FORM{formcheck} eq "confpanel") {
        my @error = form_check_confpanel();
        $FORM{temp} = temp_write("confpanel", %FORM);
        confpanel(\@error) if @error;
    } elsif ($FORM{formcheck} eq "confserial") {
        confserial_update($FORM{SERIAL});
    }
    $FORM{conffile} = ($FORM{conf_id} ? get_conffile_by_id($FORM{conf_id}) : "");

    my %conf;
    if ($FORM{temp}) {
        %conf = temp_read("confform", $FORM{temp});
    } elsif ($FORM{copy}) {
        $FORM{_conf_id} or error("設定ファイルが指定されていません。");
        my $conffile = get_conffile_by_id($FORM{_conf_id});
        ($conffile) = $conffile =~ /^([\w\_\-\.]+)$/;
        eval { require "./data/conf/$conffile"; };
        error("data/conf/${conffile}の読み込みができませんでした。: $@")
         if $@;
        %conf = conf_to_temp(conf::conf());
        $FORM{temp} = temp_write("confform", %conf, conflabel=>$conf{label});
        temp_write("confpanel", %conf, temp=>$FORM{temp});
    } elsif ($FORM{convert}) {
        $FORM{_conffile} or error("設定ファイルが指定されていません。");
        ($FORM{_conffile}) = $FORM{_conffile} =~ /^([\w\_\-\.]+)$/;
        eval { require "./data/confold/$FORM{_conffile}"; };
        error("data/confold/$FORM{_conffile}の読み込みができませんでした。: $@")
         if $@;
        {
            no strict;
            conf();
            foreach (@COND) {
                if (exists $_->[1]->{len_min}) {
                   $_->[1]->{min} = $_->[1]->{len_min};
                } elsif (exists $_->[1]->{num_min}) {
                   $_->[1]->{min} = $_->[1]->{num_min};
                }
                if (exists $_->[1]->{len_max}) {
                   $_->[1]->{max} = $_->[1]->{len_max};
                } elsif (exists $_->[1]->{num_max}) {
                   $_->[1]->{max} = $_->[1]->{num_max};
                }
            }
            %conf = conf_to_temp((
		TITLE                  => $TITLE,
		TEXT                   => $TEXT,
		BGCOLOR                => $BGCOLOR,
		LINK                   => $LINK,
		VLINK                  => $VLINK,
		ALINK                  => $ALINK,
		BACKGROUND             => $BACKGROUND,
		CONFIRM_FLAG           => $CONFIRM_FLAG,
		CONFIRM_TMPL           => $CONFIRM_TMPL,
		ERROR_FLAG             => $ERROR_FLAG,
		ERROR_TMPL             => $ERROR_TMPL,
		BLANK_STR              => $BLANK_STR,
		COND                   => [@COND],
		THANKS_FLAG            => $THANKS_FLAG,
		THANKS                 => $THANKS,
		DENY_DUPL_SEND         => $DENY_DUPL_SEND,
		SENDTO                 => $SENDTO,
		SENDFROM               => $SENDFROM,
		ENVELOPE_ADDR          => $ENVELOPE_ADDR,
		SUBJECT                => $SUBJECT,
		ATTACH_EXT             => [@ATTACH_EXT],
		ATTACH_SIZE_MAX        => $ATTACH_SIZE_MAX,
		ATTACH_TSIZE_MAX       => $ATTACH_TSIZE_MAX,
		ENCODING               => $ENCODING,
		MAIL_FORMAT_TYPE       => $MAIL_FORMAT_TYPE,
		MARK                   => $MARK,
		SEPR                   => $SEPR,
		OFT                    => $OFT,
		FORMAT                 => $FORMAT,
		AUTO_REPLY             => $AUTO_REPLY,
		REPLY_SENDFROM         => $REPLY_SENDFROM,
		REPLY_SUBJECT          => $REPLY_SUBJECT,
		REPLY_MAIL_FORMAT_TYPE => $REPLY_MAIL_FORMAT_TYPE,
		REPLY_MARK             => $REPLY_MARK,
		REPLY_SEPR             => $REPLY_SEPR,
		REPLY_OFT              => $REPLY_OFT,
		REPLY_FORMAT           => $REPLY_FORMAT,
		FILE_OUTPUT            => $FILE_OUTPUT,
		OUTPUT_FILENAME        => $OUTPUT_FILENAME,
		OUTPUT_SEPARATOR       => $OUTPUT_SEPARATOR,
		OUTPUT_FIELDS          => [@OUTPUT_FIELDS],
		FIELD_SEPARATOR        => $FIELD_SEPARATOR,
		NEWLINE_REPLACE        => $NEWLINE_REPLACE,
		EXT_SUB                => $EVAL_COMMAND,
		EXT_SUB2               => $EVAL_COMMAND2,
            ));
            $FORM{temp} = temp_write("confform", %conf, conflabel=>$conf{label});
            temp_write("confpanel", %conf, temp=>$FORM{temp});
	}
    } elsif ($FORM{conf_id}) {
        $FORM{conffile} = get_conffile_by_id($FORM{conf_id});
        ($FORM{conffile}) = $FORM{conffile} =~ /^([\w\_\-\.]+)$/;
        eval { require "./data/conf/$FORM{conffile}"; };
        error("data/conf/$FORM{conffile}の読み込みができませんでした。: $@")
         if $@;
        %conf = conf_to_temp(conf::conf(), conflabel=>$conf{label});
        $FORM{temp} = temp_write("confform", %conf);
        temp_write("confpanel", %conf, temp=>$FORM{temp});
    }

    # 2013-4-28 SENDTOは改行区切りに
    $conf{"SENDTO"} =~ s/,+/\n/g;

#error($conf{conflabel} ? $conf{conflabel} : "新規作成");
    printhtml("tmpl/admin_confform.html", errmsg => $errmsg_ref,
     conflabel => ($conf{conflabel} ? $conf{conflabel} : "新規作成"),
     conf_id_dsp=>($FORM{conf_id} ? $FORM{conf_id} : "-"),
     conffile_dsp=>($FORM{conffile} ? $FORM{conffile} : "(新規作成)"),
     temp => $FORM{temp}, conf_id=>$FORM{conf_id},
     langlist => get_langlist_select($conf{LANG}),
     ("DO_NOT_SEND:1" => $conf{DO_NOT_SEND} ? q|checked="checked"| : ""),
     ("ENVELOPE_ADDR_LINK:1" => $conf{ENVELOPE_ADDR_LINK} ? q|checked="checked"| : ""),
     (map { "FORM_FLAG:".$_ => $conf{FORM_FLAG} == $_ ? q|checked="checked"| : "" } (0,1)),
     (map { "FORM_TMPL_CHARSET:".$_ => $conf{FORM_TMPL_CHARSET} eq $_ ? q|selected="selected"| : "" } qw(auto sjis euc utf8)),
     (map { "CONFIRM_FLAG:".$_ => $conf{CONFIRM_FLAG} eq $_ ? q|checked="checked"| : "" } (0..2)),
     (map { "CONFIRM_TMPL_CHARSET:".$_ => $conf{CONFIRM_TMPL_CHARSET} eq $_ ? q|selected="selected"| : "" } qw(auto sjis euc utf8)),
     (map { "ERROR_FLAG:".$_ => $conf{ERROR_FLAG} eq $_ ? q|checked="checked"| : "" } (0..2)),
     (map { "ERROR_TMPL_CHARSET:".$_ => $conf{ERROR_TMPL_CHARSET} eq $_ ? q|selected="selected"| : "" } qw(auto sjis euc utf8)),
     (map { "THANKS_FLAG:".$_ => $conf{THANKS_FLAG} eq $_ ? q|checked="checked"| : "" } (0..2)),
     (map { "THANKS_TMPL_CHARSET:".$_ => $conf{THANKS_TMPL_CHARSET} eq $_ ? q|selected="selected"| : "" } qw(auto sjis euc utf8)),
     (map { "DENY_DUPL_SEND:".$_ => $conf{DENY_DUPL_SEND} eq $_ ? q|checked="checked"| : "" } (0,1)),
     (map { "MAIL_FORMAT_TYPE:".$_ => $conf{MAIL_FORMAT_TYPE} eq $_ ? q|checked="checked"| : "" } (0..3)),
     (map { "AUTO_REPLY:".$_ => $conf{AUTO_REPLY} eq $_ ? q|checked="checked"| : "" } (0,1)),
     (map { "REPLY_MAIL_FORMAT_TYPE:".$_ => $conf{REPLY_MAIL_FORMAT_TYPE} eq $_ ? q|checked="checked"| : "" } (0..3)),
     (map { "FILE_OUTPUT:".$_ => $conf{FILE_OUTPUT} eq $_ ? q|checked="checked"| : "" } (0,1)),
     (map { "OUTPUT_SEPARATOR:".$_ => $conf{OUTPUT_SEPARATOR} eq $_ ? q|checked="checked"| : "" } (0,1)),
     (map { $_=>html_output_escape($conf{$_}) } ("label", get_conffields())),
    );
    exit;

}

sub confform_done {

    if ($FORM{formcheck} eq "confform") {
        my @error = form_check_confform();
        temp_write("confform", %FORM);
        confform(\@error) if @error;
    }

    my %conf = (
     temp_read("confpanel", $FORM{temp}), temp_read("confform", $FORM{temp})
    );
    $conf{OUTPUT_FIELDS} = join("\n", grep { $conf{"order_$_"} ne "" } sort { $conf{"order_$a"} <=> $conf{"order_$b"} } split(/,/, $conf{cond}), qw(SERIAL REMOTE_HOST REMOTE_ADDR USER_AGENT NOW_DATE));
    $conf{ATTACH_FIELDNAME} = join(" ", grep { $conf{"_cond_attach_$_"} } split(/,/, $conf{cond}));
    my($conffile, $conf_id) = mk_conffile(%conf, conf_id=>$FORM{conf_id});

    my @conflist = get_conflist();
    my $conffile_exists;
    my @newlist;
    foreach (@conflist) {
        if ($_->{file} eq $conffile) {
            $conffile_exists = 1;
            push(@newlist, { id=>$_->{id}, file=>$conffile, label=>$conf{label}, lang=>$conf{LANG}, date=>get_datetime(time) });
        } else {
            push(@newlist, $_);
        }
    }
    unless ($conffile_exists) {
        push(@newlist, { id=>$conf_id, file=>$conffile, label=>$conf{label}, lang=>$conf{LANG}, date=>get_datetime(time) });
    }
    open(W, ">:utf8", "data/conflist.cgi")
     or error("data/conflist.cgiへ書き込みできませんでした。: $!");
    foreach my $ref(@newlist) {
        print W join("\t", map { $ref->{$_} } qw(id file label lang date)), "\n";
    }
    close(W);

    printhtml("tmpl/admin_confform_done.html",
     conf_id=>$conf_id,
    );
    exit;


}

sub confform_select {

    opendir(DIR, "data/confold")
     or error("data/confoldディレクトリを開くことができませんでした。: $!")
    ;
    my $confoldlist;
    foreach (grep(/\.pl$/, readdir(DIR))) {
        $confoldlist .= qq{<option value="$_">$_\n};
    }
    my $conflist = get_conflist();

    my @tab_disabled;
    push(@tab_disabled, 1) unless $conflist;
    push(@tab_disabled, 2) unless $confoldlist;

    printhtml("tmpl/admin_confform_select.html",
     conflist=>$conflist, confoldlist=>$confoldlist,
     disabled1=>($confoldlist ? "" : 'disabled="disabled"'),
     disabled2=>($conflist ? "" : 'disabled="disabled"'),
     tabs_disabled=>(@tab_disabled ? qq|\$('#tabs').tabs("option", "disabled", [@{[ join(",", @tab_disabled) ]}]);| : ""),
    );
    exit;

}

sub confpanel {

    my $errmsg_ref = shift || [];

    if ($FORM{formcheck} eq "confform") {
        my @error = form_check_confform();
        $FORM{temp} = temp_write("confform", %FORM);
        confform(\@error) if @error;
    } elsif ($FORM{formcheck} eq "confserial") {
        confserial_update($FORM{SERIAL});
    }
    $FORM{conffile} = ($FORM{conf_id} ? get_conffile_by_id($FORM{conf_id}) : "");

    my %conf;
    if ($FORM{temp}) {
        %conf = temp_read("confpanel", $FORM{temp});
    }
    if (!$conf{cond}) {
        confpanel_import($FORM{temp});
    }

    my @checklist = get_checklist();

    my $fields_dsp = join("", map { qq|<td class="nowrap"><a href="#" title="$_->{description}" class="tooltip">$_->{dsp}</a></td>| } @checklist);

    my $liststr;
    my $order_max = 0;
    foreach my $f(split(/,/, $conf{cond})) {
        $order_max = $conf{"order_$f"} if $order_max < $conf{"order_$f"};
        my $type_dsp = $conf{"_cond_type_$f"} || "&nbsp;";
        $conf{"_cond_email_$f"} = 1 if $f eq "EMAIL";
        $liststr .= <<STR;
<tr>
<td><input name="order_$f" size="2" value="$conf{"order_$f"}" class="r" /></td>
<td><a href="javascript:order('$f')">$f</a></td>
<td>$type_dsp<input type="hidden" name="_cond_type_$f" value="$conf{"_cond_type_$f"}" /></td>
STR
        foreach (@checklist) {
            if ($_->{flag}) {
                my $checked = $conf{"_cond_$_->{name}_$f"} ? q|checked="checked"| : "";
                $liststr .= qq|<td class="c"><input type="checkbox" name="_cond_$_->{name}_$f" value="1" $checked /></td>\n|;
            } else {
                $liststr .= qq|<td class="c"><input type="text" name="_cond_$_->{name}_$f" value="$conf{"_cond_$_->{name}_$f"}" size="$_->{size}" /></td>\n|;
            }
        }
        $liststr .= "</tr>\n";
    }
    foreach (qw(SERIAL REMOTE_HOST REMOTE_ADDR USER_AGENT NOW_DATE)) {
        $order_max = $conf{"order_$_"} if $order_max < $conf{"order_$_"};
    }

    printhtml("tmpl/admin_confpanel.html",
     errmsg => $errmsg_ref,
     confstr=>($conf{CONFID} ? $conf{CONFID} : "<font color=red>指定がありません</font>"),
     conflabel=>($conf{conflabel} ? $conf{conflabel} : "新規作成"),
     conf_id_dsp=>($FORM{conf_id} ? $FORM{conf_id} : "-"),
     conffile_dsp=>($FORM{conffile} ? $FORM{conffile} : "(新規作成)"),
     temp=>$FORM{temp}, conffile=>$FORM{conffile}, conf_id=>$FORM{conf_id},
     fields_dsp=>$fields_dsp, liststr=>$liststr,
     cond=>$conf{cond}, order_max=>$order_max,
     colspan=>scalar(@checklist)+1, colspan_s=>scalar(@checklist),
     map { "order_".$_ => $conf{"order_$_"}, "_cond_alt_".$_ => $conf{"_cond_alt_$_"} } qw(SERIAL REMOTE_HOST REMOTE_ADDR USER_AGENT NOW_DATE),
    );
    exit;

}

sub confpanel_import {

    printhtml("tmpl/admin_confpanel_import.html",
     temp=>$FORM{temp}, conffile=>$FORM{conffile}, conf_id=>$FORM{conf_id},
    );
    exit;

}

sub confpanel_import_done {

    my $content;
    if ($FORM{url}) {
        $content = get($FORM{url})
         or error('指定したURLからHTMLソースを取得できませんでした。');
    } elsif ($FORM{source}) {
        $content = $FORM{source};
    } else {
        error('URLを指定するか、HTMLソースを貼りつけてください。');
    }

    my %conf = temp_read("confpanel", $FORM{temp});
    my %cond_exists = map { $_ => 1 } split(/,/, $conf{cond});

    my $p = new HTML::SimpleParse($content);
    my %is_formtag = map { $_ => 1 } qw(input select textarea);
    my %tag;
    my @tag_order;

    my %reserved = map { $_ => 1 } reserved_words();
    foreach ($p->tree) {
        my %c = %$_;
        next if $c{type} ne "starttag";
        @c{qw(tagname content)} = split(/\s+/, $c{content}, 2);
        next unless $is_formtag{lc($c{tagname})};
        my %h = $p->parse_args( $c{content} );
        next if $reserved{$h{NAME}};
        next if lc($h{TYPE}) eq "reset" or lc($h{TYPE}) eq "submit"
         or lc($h{TYPE}) eq "image";
#        error(%h);
        push(@tag_order, $h{NAME}) unless exists $tag{$h{NAME}};
        $tag{$h{NAME}} = 1;
        $conf{"_cond_type_$h{NAME}"} = lc($c{tagname}) ne "input"
         ? lc($c{tagname}) : (lc($h{TYPE}) || 'text');
        $conf{"_cond_email_$h{NAME}"} = 1 if $h{NAME} eq "EMAIL";
        $conf{"_cond_attach_$h{NAME}"} = 1
         if $conf{"_cond_type_$h{NAME}"} eq "file";
    }
    $conf{cond} = join(",", @tag_order);
    temp_write("confpanel", %conf, temp => $FORM{temp});
    confpanel();

}

sub confserial {

    my $errmsg_ref = [];

    if ($FORM{formcheck} eq "confpanel") {
        my @error = form_check_confpanel();
        $FORM{temp} = temp_write("confpanel", %FORM);
        confpanel(\@error) if @error;
    } elsif ($FORM{formcheck} eq "confform") {
        my @error = form_check_confform();
        $FORM{temp} = temp_write("confform", %FORM);
        confform(\@error) if @error;
    } elsif ($FORM{formcheck} eq "confserial") {
        confserial_update($FORM{SERIAL});
    }
    $FORM{conffile} = ($FORM{conf_id} ? get_conffile_by_id($FORM{conf_id}) : "");

    my %conf = temp_read("confpanel", $FORM{temp});

    my $serial;
    ($FORM{conf_id}) = $FORM{conf_id} =~ /^(\w+)$/;
    if (-e "./data/serial/$FORM{conf_id}") {
        open(my $fh, "<:utf8", "./data/serial/$FORM{conf_id}")
         or error("シリアル番号ファイルが開けませんでした。: $!");
        flock($fh, LOCK_EX);
        chomp($serial = <$fh>);
        close($fh);
    } else {
        open(my $fh, ">:utf8", "./data/serial/$FORM{conf_id}")
         or error("シリアル番号ファイルが生成できませんでした。: $!");
        close($fh);
    }

    printhtml("tmpl/admin_confserial.html", errmsg => join("", map { "<li>$_</li>\n" }
     map { html_output_escape($_) } @$errmsg_ref),
     conflabel => ($conf{conflabel} ? $conf{conflabel} : "新規作成"),
     conf_id_dsp=>($FORM{conf_id} ? $FORM{conf_id} : "-"),
     conffile_dsp=>($FORM{conffile} ? $FORM{conffile} : "(新規作成)"),
     temp => $FORM{temp}, conf_id=>$FORM{conf_id},
     SERIAL => $serial,
    );
    exit;



}

sub confserial_done {

    confserial_update($FORM{SERIAL});
    printhtml("tmpl/admin_confserial_done.html",
     SERIAL => $FORM{SERIAL},
    );
    exit;

}

sub confserial_update {

    my $serial_input = shift;
    ($FORM{conf_id}) = $FORM{conf_id} =~ /^(\w+)$/;
    open(my $fh, "+<:utf8", "./data/serial/$FORM{conf_id}")
     or error("シリアル番号ファイルが開けませんでした。: $!");
    flock($fh, LOCK_EX);
    seek($fh, 0, 0);
    chomp(my $serial = <$fh>);
    if ($serial_input =~ /^([+-])(\d+)$/) {
        my $flag = $1;
        my $num = $2;
        my $digit = length($serial);
        $serial = sprintf("%0${digit}d", $flag eq "+"
         ? $serial + $num : $serial - $num);
    } elsif ($serial_input =~ /^(\d+)$/) {
        my $num = $1;
        my $digit = length($num);
#error($num, $digit);
        $serial = sprintf("%0${digit}d", $num);
    } elsif ($serial_input eq "") {
        $serial = "";
    }
    truncate($fh, 0);
    seek($fh, 0, 0);
    print $fh $serial;
    close($fh);

}

sub del {

    $FORM{conf_id} or error("CONFIDが指定されていませんでした。");
    ($FORM{conf_id}) = $FORM{conf_id} =~ /^(\w+)$/;
    my $conffile = get_conffile_by_id($FORM{conf_id});
    ($conffile) = $conffile =~ /^([\w\.\-\_]+)$/;

    my @data;
    open(my $fh, "<:utf8", "data/conflist.cgi")
     or error("data/conflist.cgiが開けませんでした。: $!");
    while (<$fh>) {
        my($conf_id) = split(/\t/);
        next if $FORM{conf_id} eq $conf_id;
        push(@data, $_);
    }

    open($fh, ">:utf8", "data/conflist.cgi")
     or error("data/conflist.cgiに書き込みできませんでした。: $!");
    print $fh @data;
    close($fh);

    unlink("./data/conf/$conffile") or error("./data/conf/${conffile}を削除できませんでした。恐れ入りますが、手動で削除してください。");
    if (-e "./data/confext/ext_$conffile") {
        unlink("./data/confext/ext_$conffile")
         or error("./data/confext/ext_${conffile}を削除できませんでした。恐れ入りますが、手動で削除してください。");
    }
    if (-e "./data/serial/$FORM{conf_id}") {
        unlink("./data/serial/$FORM{conf_id}")
         or error("./data/serial/$FORM{conf_id}を削除できませんでした。恐れ入りますが、手動で削除してください。");
    }

    print "Location: ./f_mailer_admin.cgi\n\n";
    exit;

}

sub error {

    printhtml("tmpl/admin_error.html", errmsg => join("", map { "<li>$_\n" }
     map { html_output_escape($_) } @_),
     (map { $_=>$CONF{$_} } keys %CONF), (map { $_=>$FORM{$_} } keys %FORM),
    );
    exit;

}

sub form_check {

    my $page = shift;
    if ($page eq "confform") {
        form_check_confform();
    } else {
        form_check_confpanel();
    }
}

sub form_check_confform {

    my @msg;
    $FORM{TITLE} ||= $FORM{SUBJECT};
#    $FORM{TEXT} or push(@msg, "TEXT(文字色)を指定してください。");
#    $FORM{BGCOLOR} or push(@msg, "BGCOLOR(背景色)を指定してください。");
#    $FORM{LINK} or push(@msg, "LINK(リンク文字色)を指定してください。");
#    $FORM{VLINK} ||= $FORM{LINK};
#    $FORM{ALINK} ||= $FORM{LINK};
#    $FORM{BORDER} ||= $FORM{TEXT};
    $FORM{LANG} or push(@msg, "言語モードを選択してください。");
    my $form_tmpl_errmsg_ok = 0;
    if ($FORM{CONFIRM_FLAG} eq "") {
        push(@msg, "確認画面を出すかどうかを選択してください。");
    } elsif ($FORM{CONFIRM_FLAG} == 2) {
        if ($FORM{CONFIRM_TMPL} eq "") {
            push(@msg, "確認画面のテンプレートファイルを指定してください。");
        ### 2007-7-19 http経由テンプレート読み込み対応
        } elsif ($FORM{CONFIRM_TMPL} =~ /^http/) {
            eval "use LWP::Simple;";
            error("use LWP::Simpleに失敗しました。: $@") if $@;
            unless (get($FORM{CONFIRM_TMPL})) {
                push(@msg, "指定されたURLの確認画面のテンプレートページが取得できませんでした。: $!");
            }
        } elsif (! -e $FORM{CONFIRM_TMPL}) {
            push(@msg, "指定された確認画面のテンプレートファイルが存在しません。");
        }
    }
    if ($FORM{ERROR_FLAG} eq "") {
        push(@msg, "エラー画面のテンプレートファイルを選択してください。");
    } elsif ($FORM{ERROR_FLAG} == 1) {
        my $error_html;
        if ($FORM{ERROR_TMPL} eq "") {
            push(@msg, "エラー画面のテンプレートファイルを指定してください。");
        ### 2007-7-19 http経由テンプレート読み込み対応
        } elsif ($FORM{ERROR_TMPL} =~ /^http/) {
            eval "use LWP::Simple;";
            error("use LWP::Simpleに失敗しました。: $@") if $@;
            unless ($error_html = get($FORM{ERROR_TMPL})) {
                push(@msg, "指定されたURLのエラー画面のテンプレートページが取得できませんでした。: $!");
            }
        } elsif (! -e $FORM{ERROR_TMPL}) {
            push(@msg, "エラー画面のテンプレートファイルが存在しません。");
        } else {
            if (open(my $fh, "<:utf8", $FORM{ERROR_TMPL})) {
                $error_html = join("", <$fh>);
                close($fh);
            } else {
                push(@msg, "エラー画面のテンプレートファイルが開けませんでした。: $!");
            }
        }
        if ($error_html) {
            $error_html =~ /##errmsg##/ or $error_html =~ /<!--\s*errmsg\s*-->/
             or push(@msg, "エラーテンプレートファイル内には、##errmsg## または <!-- errmsg --> のいずれかを指定してください。: $!");
        }
    }
    if ($FORM{THANKS_FLAG} eq "") {
        push(@msg, "完了画面を選択してください。");
    } elsif ($FORM{THANKS_FLAG} == 0) {
        if ($FORM{THANKS} eq "") {
            push(@msg, "完了画面のジャンプ先URLを指定してください。");
        }
    } elsif ($FORM{THANKS_FLAG} == 2) {
        if ($FORM{THANKS_TMPL} eq "") {
            push(@msg, "完了画面のテンプレートファイルを指定してください。");
        ### 2007-7-19 http経由テンプレート読み込み対応
        } elsif ($FORM{THANKS_TMPL} =~ /^http/) {
            eval {use LWP::Simple; };
            error("use LWP::Simpleに失敗しました。: $@") if $@;
            unless (get($FORM{THANKS_TMPL})) {
                push(@msg, "指定されたURLの完了画面のテンプレートページが取得できませんでした。: $!");
            }
        } elsif (! -e $FORM{THANKS_TMPL}) {
            push(@msg, "完了画面のテンプレートファイルが存在しません。");
        }
    }
    $FORM{DENY_DUPL_SEND} ||= 0;
    if ($FORM{DENY_DUPL_SEND}) {
        if ($FORM{DENY_DUPL_SEND_MIN} eq "") {
            push(@msg, "連続送信禁止期間(DENY_DUPL_SEND_MIN)を設定してください。");
        } elsif ($FORM{DENY_DUPL_SEND_MIN} =~ /\D/) {
            push(@msg, "連続送信禁止期間(DENY_DUPL_SEND_MIN)は半角数字で指定してください。");
        }
    }
    $FORM{SENDTO} or push(@msg, "管理者に送られるフォーム内容メールの送信先アドレスを指定してください。");
    for my $sendto(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $FORM{SENDTO})) {
        if (! is_email($sendto)) {
            push(@msg, "管理者に送られるフォーム内容メールの送信先アドレス($sendto)が不正です。");
        }
    }
    for my $cc(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $FORM{CC})) {
        if (! is_email($cc)) {
            push(@msg, "同報メール(CC)の送信先アドレス($cc)が不正です。");
        }
    }
    for my $bcc(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $FORM{BCC})) {
        if (! is_email($bcc)) {
            push(@msg, "同報メール(BCC)の送信先アドレス($bcc)が不正です。");
        }
    }

    $FORM{SENDFROM} or push(@msg, "管理者に送られるフォーム内容メールの送信元アドレスを指定してください。");
    $FORM{SUBJECT} or push(@msg, "管理者に送られるフォーム内容メールのタイトル(件名)を指定してください。");
    if ($FORM{ATTACH_SIZE_MAX} =~ /\D/) {
        push(@msg, "管理者に送られるフォーム内容メールの添付ファイルサイズ上限は半角数字のみで指定してください。");
    }
    if ($FORM{ATTACH_TSIZE_MAX} =~ /\D/) {
        push(@msg, "管理者に送られるフォーム内容メールの添付ファイルサイズ合計上限は半角数字のみで指定してください。");
    }
    if ($FORM{MAIL_FORMAT_TYPE} eq "") {
        push(@msg, "管理者に送られるフォーム内容メールのフォーマットを選択してください。");
    } elsif ($FORM{MAIL_FORMAT_TYPE} == 0 and !$FORM{FORMAT}) {
        push(@msg, "管理者に送られるフォーム内容メールのカスタムフォーマットを指定してください。");
    }
    if ($FORM{OFT} =~ /\D/) {
        push(@msg, "管理者に送られるフォーム内容メールの行頭からセパレータまでの文字数は半角数字のみで指定してください。");
    } elsif ($FORM{OFT} < 0 or $FORM{OFT} > 40) {
        push(@msg, "管理者に送られるフォーム内容メールの行頭からセパレータまでの文字数は0～40の範囲で指定してください。");
    }
    $FORM{AUTO_REPLY} ||= 0;
    if ($FORM{AUTO_REPLY}) {
        for my $cc(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $FORM{REPLY_CC})) {
            if (! is_email($cc)) {
                push(@msg, "自動返信メール同報送信先(REPLY_CC)の送信先アドレス($cc)が不正です。");
            }
        }
        for my $bcc(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $FORM{REPLY_BCC})) {
            if (! is_email($bcc)) {
                push(@msg, "自動返信メール隠し送信先(REPLY_BCC)の送信先アドレス($bcc)が不正です。");
            }
        }
        $FORM{REPLY_SENDFROM} ||= $FORM{SENDFROM};
        $FORM{REPLY_ENVELOPE_ADDR} ||= $FORM{ENVELOPE_ADDR};
        $FORM{REPLY_SUBJECT} or push(@msg, "自動返信メールのタイトル(件名)を指定してください。");
        if ($FORM{REPLY_MAIL_FORMAT_TYPE} eq "") {
            push(@msg, "自動返信メールのフォーマットを選択してください。");
        } elsif ($FORM{REPLY_MAIL_FORMAT_TYPE} == 0 and !$FORM{REPLY_FORMAT}) {
            push(@msg, "自動返信メールのカスタムフォーマットを指定してください。");
        }
        if ($FORM{REPLY_OFT} =~ /\D/) {
            push(@msg, "自動返信メールの行頭からセパレータまでの文字数は半角数字のみで指定してください。");
        } elsif ($FORM{REPLY_OFT} < 0 or $FORM{REPLY_OFT} > 40) {
            push(@msg, "自動返信メールの行頭からセパレータまでの文字数は0～40の範囲で指定してください。");
        }
    }
    $FORM{FILE_OUTPUT} ||= 0;
    if ($FORM{FILE_OUTPUT}) {
        if ($FORM{OUTPUT_FILENAME} eq "") {
            push(@msg, "書き出すファイル名を指定してください。");
        } elsif ($FORM{OUTPUT_FILENAME} eq ".." or $FORM{OUTPUT_FILENAME} =~ m#/#) {
            push(@msg, "書き出すファイル名にパスは指定できません。");
        }
        $FORM{OUTPUT_SEPARATOR} ||= 0;
        $FORM{FIELD_SEPARATOR} = " " if $FORM{FIELD_SEPARATOR} eq "";
    }
#    eval qq|use strict; my \$sub = sub { $FORM{EXT_SUB} };|;
#    if ($@) {
#        push(@msg, "付加的に実行したいコード1のコードが不正です。: $@");
#    }
#    eval qq|use strict; my \$sub = sub { $FORM{EXT_SUB2} };|;
#    if ($@) {
#        push(@msg, "付加的に実行したいコード2のコードが不正です。: $@");
#    }

    @msg;

}

sub form_check_confpanel {

    my @msg;
    my @checklist = get_checklist();
    my %checkname = map { $_->{name} => $_->{dsp} } @checklist;
    my %fields = map { $_ => 1 } split(/,/, $FORM{cond});
    my $type_empty;
    foreach my $f(split(/,/, $FORM{cond})) {
#        $FORM{"_cond_alt_$f"} ||= $f;
        $type_empty = 1 if $FORM{"_cond_type_$f"} eq "";
        if ($f eq "EMAIL") {
            $FORM{"_cond_email_$f"}
             or push(@msg, "name=$f の「$checkname{email}」欄にチェックしてください。")
        }
        if ($FORM{"_cond_type_$f"} eq "file") {
            unless ($FORM{"_cond_attach_$f"}) {
                push(@msg, "name=$f の「$checkname{attach}」欄にチェックしてください。");
            }
            my $check;
            foreach (grep { $_->{name} ne "alt" and $_->{name} ne "attach" and $_->{name} ne "required" } @checklist) {
                $check = 1 if $FORM{"_cond_$_->{name}_$f"};
            }
            if ($check) {
                push(@msg, "name=$f の「$checkname{attach}」欄にチェックしている場合は、「$checkname{required}」以外の欄にチェックできません。");
            }
        } elsif ($FORM{"_cond_attach_$f"}) {
            my $check;
            foreach (grep { $_->{name} ne "alt" and  $_->{name} ne "attach" and $_->{name} ne "required" } @checklist) {
                $check = 1 if $FORM{"_cond_$_->{name}_$f"};
            }
            if ($check) {
                push(@msg, "name=$f の「$checkname{attach}」欄にチェックしている場合は、「$checkname{required}」以外の欄にチェックできません。");
            }
        } else {
            if ($FORM{"_cond_compare_$f"}) {
                $fields{$f} or push(@msg, "name=$f の「$checkname{compare}」にチェックを入れている場合は、確認用の name=${f}2 のフィールドが必要です。");
            }
        }
    }
    if ($type_empty) {
        push(@msg, '項目名の型(type=input/select/radio/text/textarea)が空欄になっている項目があります。旧バージョンの設定ファイルをインポートしただけですとこの現象が起こります。「入力条件設定対象フォームの読み込み」を行ってください。');
    }
    @msg;

}

sub form_check_sysconfform {

    my @msg;
    if ($FORM{SENDMAIL_FLAG} eq "") {
        push(@msg, "メール送信モードを選択してください。");
    } elsif ($FORM{SENDMAIL_FLAG} == 0) {
        if ($FORM{SENDMAIL} eq "") {
            push(@msg, "sendmailのパスを指定してください。");
        } elsif (! -e $FORM{SENDMAIL}) {
            push(@msg, "指定されたsendmailのパスが存在しません。");
        }
    } elsif ($FORM{SENDMAIL_FLAG} == 1) {
        eval "use Net::SMTP;";
        push(@msg, "Net::SMTPモジュールがインストールされていません。") if $@;
        if ($FORM{SMTP_HOST} eq "") {
            push(@msg, "SMTPホスト名/IPアドレスを指定してください。");
        } else {
            (my $smtp_host) = $FORM{SMTP_HOST} =~ /^([\w\.\-\_]*)$/;
            if ($smtp_host) {
                eval "use Net::SMTP;";
                my $smtp = Net::SMTP->new($smtp_host)
                 or push(@msg, "指定されたSMTPホスト名/IPアドレス(=$FORM{SMTP_HOST})で接続できませんでした。");
                ### 2007-7-19 SMTP_AUTH対応
                if ($FORM{USE_SMTP_AUTH}) {
                    eval qq{use MIME::Base64};
                    push(@msg, "MIME::Base64がインストールされていません。") if $@;
                    eval qq{use Authen::SASL};
                    push(@msg, "Authen::SASLがインストールされていません。") if $@;
                    if ($FORM{SMTP_AUTH_ID} eq "" or $FORM{SMTP_AUTH_PASSWD} eq "") {
                        push(@msg, "SMTP_AUTHに使用するID/パスワードを指定してください。");
                    } else {
                        $smtp->auth($FORM{SMTP_AUTH_ID}, $FORM{SMTP_AUTH_PASSWD})
                         or push(@msg, "SMTP_AUTHのID/パスワードで認証できませんでした。: $!");
                    }
                }
            } else {
                push(@msg, "指定されたSMTPホスト名/IPアドレス(=$FORM{SMTP_HOST})に不正な文字が含まれていました。");
            }
        }
    }
#    $FORM{SYS_TEXT} || push(@msg, "管理画面の文字色を指定してください。");
#    $FORM{SYS_BGCOLOR} || push(@msg, "管理画面の背景色を指定してください。");
#    $FORM{SYS_LINK} || push(@msg, "管理画面のリンク文字色を指定してください。");
#    $FORM{SYS_VLINK} ||= $FORM{LINK};
#    $FORM{SYS_ALINK} ||= $FORM{LINK};
#    $FORM{SYS_BORDER} ||= $FORM{SYS_TEXT};

    my $remote_host = remote_host();
    my $ok;
    foreach my $host(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $FORM{ALLOW_FROM})) {
        next if $host eq "";
        $ok = 1 if $remote_host =~ /$host$/i or $ENV{REMOTE_ADDR} =~ /^$host/;
    }
    if ($FORM{ALLOW_FROM} and !$ok) {
        push(@msg, "管理ページの接続元制限に現在の接続元を指定してください。");
    }

    @msg;

}

sub login {

    $FORM{passwd} or error("パスワードを入力してください。");
    passwd_write() unless -e "data/passwd.cgi";
    passwd_compare($FORM{passwd}) or error("パスワードが違います。");

    set_cookie("FORM_MAILER_ADMIN", "", "login");
    set_cookie("FORM_MAILER_ADMIN_CACHE", 30 * 86400,
     ($FORM{do_cache} ? $FORM{passwd} : ""));
    print "Location: f_mailer_admin.cgi\n\n";
    exit;

}

sub login_form {

    my $passwd = get_cookie("FORM_MAILER_ADMIN_CACHE");
    printhtml("tmpl/admin_login_form.html", passwd=>$passwd,
     do_cache=>$passwd ? q|checked="checked"| : "");
    exit;

}

sub logout {

    set_cookie("FORM_MAILER_ADMIN");
    printhtml("tmpl/admin_logout.html");
    exit;

}

sub menu {

    temp_del(2);  ### 2時間経過したtempファイルを削除

    my $list;
    my %lang = map { $_->[0] => $_->[1] } get_langlist();
    foreach my $conf(get_conflist()) {
        my($conf_id, $filename, $label, $lang, $date) = map { $conf->{$_} } qw(id file label lang date);
        $lang ||= "ja";
        my $last_update = $date || get_datetime((stat("data/conf/$filename"))[9]);
        $list .= <<STR;
<tr>
<td>$label</td>
<td>$conf_id</td>
<td>$filename</td>
<td>ext_$filename</td>
<td class="nowrap">($lang)$lang{$lang}</td>
<td class="nowrap">$last_update</td>
<td class="nowrap">
<button onclick="location.href='f_mailer_admin.cgi?confform=1;conf_id=$conf_id'">設定/変更</button>
<button onclick="location.href='f_mailer_admin.cgi?confserial=1;conf_id=$conf_id'">シリアル番号</button>
<button onclick="if(confirm('この設定を削除します。一度削除すると元には戻せません。よろしいですか?')){location.href='f_mailer_admin.cgi?del=1;conf_id=$conf_id'}">削除</button>
</td>
</tr>
STR
    }
    $list ||= q|<tr><td colspan="7" class="c">(登録がありません)</td></tr>|;

    printhtml("tmpl/admin_menu.html", list=>$list);
    exit;

}

sub sysconfform {

    my $errmsg_ref = shift || [];
    my %conf = @$errmsg_ref ? %FORM : %CONF;

    printhtml("tmpl/admin_sysconfform.html", errmsg => $errmsg_ref,
     langlist => get_langlist_select($conf{LANG_DEFAULT}),
     rh => remote_host(), ip => $ENV{"REMOTE_ADDR"},
     "USE_SMTP_AUTH:1" => ($conf{USE_SMTP_AUTH} ? q|checked="checked"| : ""),
     (map { "SENDMAIL_FLAG:".$_ => $conf{SENDMAIL_FLAG} eq $_ ? q|checked="checked"| : "" } (0,1)),
     (map { $_=>$conf{$_} } qw(SENDMAIL SMTP_HOST USE_SMTP_AUTH SMTP_AUTH_ID SMTP_AUTH_PASSWD ALLOW_FROM)),
    );
    exit;
}

sub sysconfform_done {

    my @error = form_check_sysconfform();
    sysconfform(\@error) if @error;

    mk_sysconffile(%FORM);

    printhtml("tmpl/admin_sysconfform_done.html");
    exit;

}
