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
use vars qw(%CONF %FORM %alt $q $name_list_ref %ERRMSG $smtp);
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

	my($charset, $subject) = @_;
	return sprintf("=?%s?B?%s?=", $charset, base64($subject, "nofold"));

}

sub comma {

	my $num = shift;
	1 while $num =~ s/(.*\d)(\d\d\d)/$1,$2/;
	$num or 0;

}

sub data_convert {

	my %form = @_;

	my $code = $CONF{FORM_TMPL_CHARSET} eq "auto"
	 ? ($form{GETCODE} ? Unicode::Japanese->new($form{GETCODE})->getcode() : "utf8")
	 : $CONF{FORM_TMPL_CHARSET};

	my %form2;
	while (my($key, $value) = each %form) {
		$key = Unicode::Japanese->new($key, $code)->get if $code ne "utf8";
		$value = Unicode::Japanese->new($value, $code)->get if $code ne "utf8";
		$form2{$key} = $value;
	}
	if ($code ne "utf8") {
		for (@$name_list_ref) { $_ = Unicode::Japanese->new($_, $code)->get }
	}
	%form2;

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
				$form{$name} = $each . "";
			}
		}
		push(@name_list, $name) unless $form_name_cnt{$name}++;
	}
	return \@name_list, %form;

}

sub error_ {

	print "Content-type: text/html; charset=utf-8\n\n";
	print @_;
	exit;

}

sub get_checklist {

	open(my $fh, "<", "data/check.txt")
	 or error(get_errmsg("200", $!));
	my @list;
	while (<$fh>) {
		chomp;
		my($name, $dsp, $flag, $size, $description) = split(/\t/);
		push(@list, { name=>$name, dsp=>$dsp, flag=>$flag, size=>$size, description=>$description });
	}
	close($fh);
	return @list;

}

sub get_conffile_by_id {

	my $conf_id = shift;
	open(my $fh, "<", "data/conflist.cgi")
	 or error_(get_errmsg("210", $!));
	while (<$fh>) {
		my($id, $file, $label) = split(/\t/);
		return $file if $id eq $conf_id;
	}
	close($fh);
	error_(get_errmsg("211", $conf_id));

}

sub get_conflist {

	open(my $fh, "<", "data/conflist.cgi")
	 or error(get_errmsg("220", $!));
	my $conflist;
	my @list;
	while (<$fh>) {
		chomp;
		my($id, $file, $label, $lang, $date) = split(/\t/);
		$conflist .= qq{<option value="$id">$label($id)</option>\n};
		push(@list, { id=>$id, file=>$file, label=>$label, lang=>$lang, date=>$date });
	}
	close($fh);
	return wantarray ? @list : $conflist;

}

sub get_cookie {

	my $cookie_name = shift;
	error(get_errmsg("230")) if !$cookie_name;
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

sub get_datetime_for_file_output {

	my $time = shift || time;

	my($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime($time);
	my %dt;
	@dt{qw(Y M D H I S)} = (
		$year+1900,
		sprintf("%02d", ++$mon),
		sprintf("%02d", $mday),
		sprintf("%02d", $hour),
		sprintf("%02d", $min),
		sprintf("%02d", $sec),
	);
	return %dt;

}

sub get_datetime_for_mailheader {

	my $time = shift || time;
	my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime($time + 32400);
	sprintf("%s, %d %s %04d %02d:%02d:%02d +0900",
	 (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday],
	 $mday, (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon],
	 $year+1900, $hour, $min, $sec);

}

sub get_errmsg {

	my ($code, @v) = @_;
	my $errmsg = $ERRMSG{$code};
	$errmsg =~ s/<v(\d)>/$v[$1-1]/g;
	return $errmsg;

}

sub get_formdatalist {

	my %ignore_name = map { $_ => 1 } reserved_words();
	my $list;
	foreach my $name(@$name_list_ref) {
		next if $ignore_name{$name};
		my $name_dsp = $alt{$name} || $name;
		$list .= <<STR;
<tr><th class="l">$name_dsp</th><td>##$name##</td></tr>
STR
	}

	$list =~ s/##([^#]+)##/replace($1,'html', \%FORM)/eg;
	$list;

}

sub h {

	return html_output_escape($_[0]);

}

# 半角英数記号のみを全角変換
sub h2z {

	 my($str) = @_;
	 return Unicode::Japanese->new($str, "utf8")->h2zSym->h2zNum->h2zAlpha->get;

}

# 半角カタカナのみを全角変換
sub h2z_kana {

	my($str) = @_;
	return Unicode::Japanese->new($str, "utf8")->h2zKana->get;

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

	umask 0;

	my($temp, $param) = @_;
	my $filename = $q->param($param) . "";
	my $stream;
	my $param_enc = uri_escape($param);

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
		my @path = split(/\\/, $filename);
		$filename = $path[-1];
		my $filename_enc = uri_escape($filename);
		(my $filename_enc_clean) = $filename_enc =~ /^([\da-zA-Z_.,%-]+)$/;
		return "taint check error: $filename"
		 unless $filename_enc_clean eq $filename_enc;
		my $filename_path_enc = "./temp/$temp-$param_enc-$filename_enc_clean";
		open(my $fh, ">", $filename_path_enc)
		 or return get_errmsg("240", $!, $filename_path_enc);
		print $fh $stream;
		close($fh);
		return;
	} else {
		return get_errmsg("241");
	}

}

sub is_ascii {

	return $_[0] =~ /[^\t\n\x20-\x7e]/ ? 0 : 1;

}

sub is_valid_date {

#日付が存在するかチェックする
#引数： 年、月 (1-12)、日
#戻り値：フラグ (1=OK、0=NG) 
	use Time::Local;

	my ($year, $month, $day) = @_;
	$year and $month and $day
	 and $year =~ /^\d+$/ and $month =~ /^\d+$/ and $day =~ /^\d+$/
	or return 0;

	my $epoch = eval { timelocal(0, 0, 0, $day, $month-1, $year) };

	return (defined $epoch) ? 1 : 0;

}

sub is_email {

	return $_[0] =~ /^[-_.!*a-zA-Z0-9\/&+%\#]+\@[-_.a-zA-Z0-9]+\.(?:[a-zA-Z]{2,4})$/ ? 1 : 0;
 
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
		if ($f_value and ! is_email($f_value)) {
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
		return Unicode::Japanese->new($f_value, "utf8")->hira2kata->get;
	};
	$condcheck{hira_only} = sub {
		my($f_name, $alt_name, $f_value) = @_;
		my $f_value_ = Unicode::Japanese->new($f_value, "utf8")->get;
		my @errmsg;
		unless ($f_value_ =~ /^[\p{InHiragana}\x{3000}\x{30fc}]*$/o) { # ひらがな、全角スペース(　)、長音記号(ー)
			push(@errmsg, set_errmsg(key=>"hira_only", f_name=>($alt_name or $f_name)));
		}
		($f_value, @errmsg);
	};
	$condcheck{kata2hira} = sub {
		my($f_name, $alt_name, $f_value) = @_;
		return Unicode::Japanese->new($f_value, "utf8")->kata2hira->get;
	};
	$condcheck{kata_only} = sub {
		my($f_name, $alt_name, $f_value) = @_;
		my $f_value_ = Unicode::Japanese->new($f_value, "utf8")->getu;
		my @errmsg;
		unless ($f_value_ =~ /^[\p{InKatakana}\x{3000}\x{30a0}\x{30fc}]*$/o) { # カタカナ、全角スペース(　)、二重ハイフン(゠)、長音記号(ー)
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
		(trim($f_value)); # String::Util::trim 使用
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

sub load_errmsg {

	my $lang = shift || "en";
	my %errmsg;

	open(my $fh, "<", "data/errmsg_$lang.txt")
	 or error_("Can't load errmsg data: $!");
	while (<$fh>) {
		chomp;
		my($code, $str) = split(/\t/, $_, 2);
		$errmsg{$code} = $str;
	}
	return %errmsg;

}

sub mk_errmsg {

	my $errmsg_ref = shift || [];

	my $errmsg = join("\n", map { qq|<li $CONF{"ERRMSG_STYLE_LI"}>$_</li>| } map { h($_) } @$errmsg_ref);
	if ($errmsg ne "") {
		return qq|<ul $CONF{"ERRMSG_STYLE_UL"}>\n$errmsg\n</ul>|;
	}
	return;

}

sub mojichk {

	my($str, $fname) = @_;
	my @error_char;
#my @debug;
	for my $char(Unicode::Japanese->new($str, "utf8")->getu =~ /./g) {
		my $code = lc(unpack("H*", Unicode::Japanese->new($char, "utf8")->sjis));
#push(@debug, $code);
		next if length($code) < 3;
		if ($code lt '8140' or $code gt '84be' and $code lt '889f' or $code gt '9872' and $code lt '989f' or $code gt 'eaa4') {
			push(@error_char, "$char");
		}
	}

#die "@debug";
	@error_char
	 ? (get_errmsg("250", $fname, join(q|", "|, map { Unicode::Japanese->new($_, "utf8")->get } @error_char)))
	 : "";

}

sub nl2br {

	my $str = shift;
	$str =~ s#\r\n|\r|\n#<br />\n#g;
	return $str;
}

sub printhtml {

	my($filename, %tr) = @_;

	my $charset;
	if (exists $tr{CHARSET}) {
		$charset = $tr{CHARSET};
		delete $tr{CHARSET};
	}
	$charset ||= "auto";

	open(my $fh, "<", "tmpl/_header.html");
	my $header = join("", <$fh>);
	$header =~ s/##STYLESHEET##/$CONF{STYLESHEET}/g;
	map { $header =~ s/##$_##/$CONF{$_}/g } qw(TEXT BGCOLOR LINK VLINK ALINK BACKGROUND BORDER SYS_TEXT SYS_BGCOLOR SYS_LINK SYS_VLINK SYS_ALINK SYS_BACKGROUND SYS_BORDER);
	close($fh);
	open($fh, "<", "tmpl/_footer.html");
	my $footer = join("", <$fh>);
	close($fh);
	my($code, $htmlstr) = printhtml_getpage($charset, { filename=>$filename,
	 header=>$header, footer=>$footer, errmsg=>$tr{"errmsg"} });
	foreach my $key(keys %tr) {
		$htmlstr =~ s/##$key##/$tr{$key}/g;
	}
	printhtml_output($code, $htmlstr);

}

sub printhtml_getpage {

	my($charset, $opt) = @_;
	my %opt = %$opt;
#die Dumper(\%opt);
	### 2007-7-19 http経由テンプレート読み込み対応
	my $htmlstr;
	if ($opt{filename} =~ /^http/) {
		eval "use LWP::Simple;";
		error_(get_errmsg("260", $@)) if $@;
		$opt{filename} =~ s/##([^#]+)##/uri_escape($FORM{$1})/eg;
		$htmlstr = encode_utf8(get($opt{filename}));
	} else {
		open(my $fh, "<", $opt{filename}) or error_(get_errmsg("261", $@, $opt{filename}));
		$htmlstr = join("", <$fh>);
		close($fh);
	}
	my $code;
	if ($ENV{SCRIPT_FILENAME} =~ m#admin# or $opt{filename} =~ m#\./tmpl/default/#) {
		$charset = "utf8";
	} else{
		my $code = $charset || Unicode::Japanese->new($htmlstr)->getcode() || "utf8";
		$code = "utf8" if $code =~ /utf/;
		$charset = $code if $charset eq "auto";
	### 2013-10-30 常にコード変換する(utf-8→utf-8の文字化け回避)
		$htmlstr = Unicode::Japanese->new($htmlstr, $charset)->get if $charset ne "utf8";
	}
	$htmlstr =~ s/<!-- header -->/$opt{header}/;
	$htmlstr =~ s/<!-- footer -->/$opt{footer}/;
	$htmlstr =~ s/<!-- errmsg -->/mk_errmsg($opt{errmsg})/e;
	######################################################################
	### 下の処理を変更しないでください。                               ###
	### 各ページのフッタ部分の著作権表示をなくしたい場合は、届け出の上 ###
	### 利用規約第10条第5項の料金をお支払いいただきます。              ###
	### http://www.psl.ne.jp/lab/copyright.html                        ###
	######################################################################
	$htmlstr =~ s/##COPYRIGHT##/$ENV{SCRIPT_FILENAME} =~ m#admin# ? $CONF{copyright_html_footer_admin} : $CONF{copyright_html_footer}/eg;
	$htmlstr =~ s/##prod_name##/$CONF{prod_name}/g;
	$htmlstr =~ s/##version##/$CONF{version}/g;
	($charset, $htmlstr);
}

sub printhtml_output {

	my ($code, $htmlstr) = @_;

	print "Content-type: text/html; charset=";
	if ($code eq "sjis") {
		print "Shift_JIS\n\n", Unicode::Japanese->new($htmlstr, "utf8")->sjis;
	} elsif ($code eq "euc") {
		print "euc-jp\n\n", Unicode::Japanese->new($htmlstr, "utf8")->euc;
	} else {
#		print "utf-8\n\n", Unicode::Japanese->new($htmlstr, "utf8")->get;
		print "utf-8\n\n", $htmlstr;
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
		$value = h($value);
		$value = nl2br($value);
	}

	$value eq '' ? $CONF{BLANK_STR} : $value;

}

sub reserved_words {

	qw(CONF CONFID TEMP VALUES CREDIT SEND_FORCED GETCODE DUMMY);
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

	if ($opt{fromname}) {
		$opt{fromname} = qq{"$opt{fromname}" <$opt{from}>};
	} else {
		$opt{fromname} = $opt{from};
	}
	my $date = get_datetime_for_mailheader(time);

	### Net::SMTPモード
	if ($CONF{SENDMAIL_FLAG}) {

		eval qq{use Net::SMTP};
		error_("Net::SMTPがインストールされていません。: $@") if $@;
		if ($CONF{USE_SMTP_AUTH}) {
			eval qq{use MIME::Base64};
			error_("MIME::Base64がインストールされていません。: $@") if $@;
			eval qq{use Authen::SASL};
			error_("Authen::SASLがインストールされていません。: $@") if $@;
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
		if ($opt{cc}) {
			$smtp->cc(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $opt{cc}));
		}
		if ($opt{bcc}) {
			$smtp->bcc(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $opt{bcc}));
		}
		$smtp->data();
		$smtp->datasend("Date: $date\n");
		$smtp->datasend("To: $opt{mailto}\n");
		if ($opt{cc}) {
			$smtp->datasend("Cc: ". join(",\n\t", split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $opt{cc})). "\n");
		}
		if ($opt{bcc}) {
			$smtp->datasend("Bcc: ". join(",\n\t", split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $opt{bcc})). "\n");
		}
		$smtp->datasend("From: $opt{fromname}\n");
		$smtp->datasend("Subject: $opt{subject}\n");
		$smtp->datasend($opt{mailstr});
		$smtp->dataend();

	### sendmailモード
	} else {

#		open(my $mail, "| $CONF{SENDMAIL} -t $opt{envelope}")
		open(my $mail, "| $CONF{SENDMAIL} -t")
			 or error(get_errmsg("270", $!));
		print $mail "Date: $date\n";
		print $mail "To: $opt{mailto}\n";
		if ($opt{cc}) {
			print $mail "Cc: ", join(",\n\t", split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $opt{cc})), "\n";
		}
		if ($opt{bcc}) {
			print $mail "Bcc: ", join(",\n\t", split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $opt{bcc})), "\n";
		}
		print $mail "From: $opt{fromname}\n";
		print $mail "Subject: $opt{subject}\n";
		print $mail $opt{mailstr};
		close($mail) or error(get_errmsg("271", $!));

	}


}

sub serial_increment {

	my $conf_id = shift;
	($conf_id) = $conf_id =~ /^(\w+)$/;
	unless (-e "./data/serial/$conf_id") {
		open(my $fh, ">", "./data/serial/$conf_id")
		 or error(get_errmsg("280", $!));
		close($fh);
	}
	open(my $fh, "+<", "./data/serial/$conf_id")
	 or error(get_errmsg("281", $!));
	flock($fh, LOCK_EX);
	seek($fh, 0, 0);
	my $serial = <$fh> || 0;
	my $length = length($serial);
#error($length,$serial);
	$serial = sprintf("%0${length}d", ++$serial);
#error($serial);
	truncate($fh, 0);
	seek($fh, 0, 0);
	print $fh $serial;
	close($fh);

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

	%ERRMSG = load_errmsg($CONF{LANG});

	### 2008-6-12 暫定的にこの位置に指定
	### 管理画面で設定できるようにする
	$CONF{errmsg} = {
	# ##f_name##…フィールド名
	# ##cond##…min/max条件で、上限あるいは下限値
	# ##eval##…regex/regex2条件で、evalに失敗したときに返される$@の値
	# ##str##…required条件で、
	#           radio/checkbox/selectは「required_choose」
	#           その他は「required_input」
	compare  => get_errmsg("290",  "##f_name##"),
	d_only   => get_errmsg("291",  "##f_name##"),
#	deny_rel => q|##f_name##を正しく入力してください。|,
	email    => get_errmsg("292",  "##f_name##"),
	hira_only=> get_errmsg("293",  "##f_name##"),
	kata_only=> get_errmsg("294",  "##f_name##"),
#	len_max  => q|##f_name##は##cond##文字(半角)以下で入力してください。|,
	len_max  => get_errmsg("295",  "##f_name##", "##cond2##"),
	num_max  => get_errmsg("296",  "##f_name##", "##cond##"),
	max      => get_errmsg("297",  "##f_name##", "##cond##"),
	len_min  => get_errmsg("298",  "##f_name##", "##cond##"),
	num_min  => get_errmsg("299",  "##f_name##", "##cond##"),
	min      => get_errmsg("300",  "##f_name##", "##cond##"),
	regex    => get_errmsg("292",  "##f_name##"),
	regex2   => get_errmsg("292",  "##f_name##"),
	regex_eval_error => get_errmsg("301",  "##f_name##", "##eval##"),
	required => get_errmsg("302",  "##f_name##", "##str##"),
	required_choose => get_errmsg("303"),
	required_input  => get_errmsg("304"),
	url      => get_errmsg("292",  "##f_name##"),
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
		version   => q{0.7 beta160512},
		a_email   => q{info@psl.ne.jp},
		a_url     => q{http://www.psl.ne.jp/},
		copyright => q{&copy;1997-2016},
		copyright2 => q{(c)1997-2016},
	);
#	chomp($PROD{copyright_html_footer} = <<STR);
#<a href="$PROD{a_url}" target="_blank"><strong>$PROD{prod_name} v$PROD{version}</strong></a>
#STR
#	chomp($PROD{copyright_html_footer_admin} = <<STR);
#<strong>$PROD{prod_name} v$PROD{version}</strong>
#$PROD{copyright} <a href="$PROD{a_url}" onclick="this.target='_blank'">Perl Script Laboratory</a> All rights reserved.
#STR

#	chomp($PROD{copyright_mail_footer} = <<STR);
#----
#$PROD{"copyright2"} $PROD{"prod_name"} v$PROD{"version"}
#$PROD{"a_url"}
#STR
##############################################
###              ここまで                  ###
##############################################
	return %PROD;

}

sub temp_del {

	my $hours = shift;

	my $now = time;
	opendir(DIR, "temp")
	 or error(get_errmsg("310", $!));
	foreach my $file(grep(!/^\.\.?/, readdir(DIR))) {
		($file) = $file =~ /^(\d+.*)$/;
		unlink("temp/$file") if (stat("temp/$file"))[10] < $now - $hours * 3600;
	}

}

sub temp_read {

	my($page, $temp) = @_;
	open(my $fh, "<", "temp/$temp-$page")
#     or error("temp/$temp-$pageを開けませんでした。: $!");
	;
	my %form;
	while (<$fh>) {
		chomp;
		my($k, $v) = split(/:/, $_, 2);
		$v =~ s/\x0b/\n/g;
		$form{$k} = $v;
		for my $v_(split(/\!\!\!/, $v)) {
			$form{"$k\0$v_"} = $v_;
		}
	}
	close($fh);

	return %form;

}

sub temp_write {

	my($page, %form) = @_;
	my $temp = $ENV{SCRIPT_FILENAME} =~ /admin/ ? "temp" : "TEMP";
	$form{$temp} ||= time . $$;

	($form{$temp}) = $form{$temp} =~ /^(\d+)$/;
#    ($page) = $page =~ /^(\w+)$/;
	open(W, ">",  "temp/$form{$temp}-$page")
	 or error(get_errmsg("320", $!));
	foreach ($page eq "confform" ? ("label", get_conffields()) : keys %form) {
		$form{$_} =~ s/\r?\n/\x0b/g;
		print W "$_:$form{$_}\n";
	}
	close(W);

	return $form{$temp};

}

sub uri_escape {

	my $str = shift;
	$str =~ s/(\W)/'%' . unpack('H2', $1)/eg;
	return $str;

}

sub uuencode {

	my($str, $filename) = @_;
	$str = pack('u', $str);
	$str = "begin 644 $filename\n$str\`\nend";
	$str;

}

sub z2h {

	 my($str) = @_;
	 return Unicode::Japanese->new($str, "utf8")->z2h->h2zKana->get;

}

1;
