#!/usr/bin/perl
#BEGIN{ print "Content-type: text/html\n\n"; $| =1; open(STDERR, ">&STDOUT"); }

use strict;
use lib qw(./module ./lib);
use vars qw($q %FORM %CONF $name_list_ref %alt %ERRMSG);
#use utf8;
use Encode;
use CGI;
use Unicode::Japanese;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Session;
use HTML::SimpleParse;
use Data::Dumper;
use JSON;
use Fcntl ':flock';
use String::Util qw(trim);
use Digest::MD5  qw(md5_hex);
use URI::Escape;
use Carp 'verbose';
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };
sub d { die Dumper @_ }
$ENV{"PATH"} = "/usr/bin:/usr/sbin:/usr/local/bin:/bin";
require "f_mailer_lib.pl";
require "f_mailer_ajax.pl";
require "f_mailer_condcheck.pl";
umask 0;

$q = new CGI;
%CONF = (setver(), sysconf_read());
set_errmsg_init();

($name_list_ref, %FORM) = decoding($q);
error(get_errmsg("000")) unless keys %FORM;

### 設定ファイルのロード
my %conf;
if ($FORM{"CONFID"}) {
	%conf = conf_read($FORM{"CONFID"});
} else {
	error(get_errmsg("003"));
}

### 拡張ファイルのロード
my $file = get_conffile_by_id($FORM{"CONFID"});
if (-e qq|./data/confext/ext_$file.pl|) {
	$CONF{"EXTFILE_EXIST"} = 1;
	eval qq|require qq[./data/confext/ext_$file.pl];|;
	error(get_errmsg("004", $@, $file)) if $@;
}

%CONF = (%CONF, %conf);
$CONF{"CGISESSID"} = get_cookie("CGISESSID");
$CONF{"session"} = new CGI::Session("driver:File", $CONF{"CGISESSID"}, { "Directory" => "./temp" });
$CONF{"__token"} = get_sid();
set_errmsg_init(); ### フォームの使用言語確定後ロード
%FORM = data_convert(%FORM);
$FORM{"REMOTE_HOST"} = remote_host();
$FORM{"REMOTE_ADDR"} = $ENV{"REMOTE_ADDR"};
$FORM{"USER_AGENT"}  = $ENV{"HTTP_USER_AGENT"};
$FORM{"NOW_DATE"}    = get_datetime(time);

### CSRF対策 トークン発行処理
### TEMPで扱えるようにする
token_publish();
ajax_token() if $FORM{"ajax_token"};

%alt = setalt();

if ($FORM{"FORM"}) {
	%FORM = (%FORM, $CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|));
	form();
}

$name_list_ref = [split(/,/, $FORM{"FIELDLIST"})] if exists $FORM{"FIELDLIST"};
ajax_delete() if $FORM{"ajax_delete"};
ajax_file_check() if $FORM{"ajax_file_check"};
ajax_upload() if $FORM{"ajax_upload"};

if (($FORM{"SEND_FORCED"} or !$CONF{"CONFIRM_FLAG"} and !$FORM{"CONFIRM_FORCED"})) {

	%FORM = (%FORM, $CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|));
	checkvalues();
	sendmail_do();

} else {

	$CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|, \%FORM);
	%FORM = (%FORM, $CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|));
	checkvalues();
	confirm();
}


sub confirm {

	output_form("CONFIRM") if $CONF{"CONFIRM_FLAG"} == 2;

	printhtml(qq|./tmpl/default/@{[ $CONF{"LANG"} or $CONF{"LANG_DEFAULT"} ]}/confirm.html|,
#		"CHARSET" =>"sjis",
		"list" => get_formdatalist(),
		"CONFID" =>$FORM{"CONFID"},
		"TEMP" => $FORM{"TEMP"},
		(map { $_ => $CONF{$_} } keys %CONF),
		map { $_ => replace($_, "html", \%FORM) } map { $_->[0] } @{$CONF{"COND"}}
	);
	exit;

}

sub error_formcheck {

	error(@_) unless $CONF{"FORM_FLAG"};

	output_form("FORM", \@_);

}

sub form {

	output_form("FORM");

}

sub output_form {

	require "f_mailer_get_output_form.pl";

	my($phase, $errmsg_ref) = @_;
#die "$phase,$errmsg," , caller();
#d(mk_errmsg($errmsg_ref));

	my($code, $htmlstr) = printhtml_getpage(
	 ($CONF{"${phase}_TMPL_CHARSET"} || "auto"),
	 {
	   "filename" => $CONF{"${phase}_TMPL"},
	   "errmsg" => ($errmsg_ref || []),
	 }
	);

	my %d;
	if (ref $errmsg_ref) {
		%d = { $CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|) };
		$htmlstr =~ s|<!--\s*errmsg\s*-->|mk_errmsg($errmsg_ref)|ie;
		$htmlstr =~ s|##errmsg##|mk_errmsg($errmsg_ref)|ie;
	} else {
		%d = %FORM;
	}
#d(\%d);
	$htmlstr =~ s/##list##/get_formdatalist()/e;
	$htmlstr = get_output_form($phase, $htmlstr, %d, "TEMP"=>$FORM{"TEMP"});
	foreach my $key(keys %d) {
		eval { $htmlstr =~ s/##\Q$key\E##/Unicode::Japanese->new(($phase eq "CONFIRM" or $phase eq "THANKS") ? replace($key,'html',\%d) : $d{$key}, "utf8")->get/eg; };
		error_("$key, $d{$key}, $@") if $@;
	}
	printhtml_output($code, $htmlstr);
	exit;

}

sub sendmail_do {

	my @errmsg;

	if ($CONF{"DENY_DUPL_SEND"}) {
		if (get_cookie($FORM{"CONFID"})) {
			error(get_errmsg("110"));
		}
	}

	%FORM = (%FORM, %{ $CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|) });
	$name_list_ref = [split(/,/, $FORM{"FIELDLIST"})];

	### 添付ファイル名の読み込み
	my %exists; # = ajax_file_check("thru" => 1);
#	for my $fname(@{$CONF{"ATTACH_FIELDNAME"}}) {
#		if ($exists{$fname}{"name"} ne "") {
#			$FORM{$fname} = $exists{$fname}{"name"};
#		} else {
#			$FORM{$fname} = "";
#		}
#	}

	### 拡張コードの実行
	### エラーメッセージのリストを受け取ります。
	if ($CONF{"EXTFILE_EXIST"}) {
		my @xerrmsg = ext_sub2();
		if (ref($xerrmsg[0])) {
			@xerrmsg = @{$xerrmsg[0]};
		}
		push(@errmsg, @xerrmsg) if @xerrmsg;
	}

	error(@errmsg) if @errmsg;

	### シリアル番号の取得
	$FORM{"SERIAL"} = serial_increment($FORM{"CONFID"});

	### v0.72より、Fromヘッダアドレスの優先切替対応
	my $sendfrom = $CONF{"SENDFROM_EMAIL_FORCED"} ? ($FORM{"EMAIL"} || $CONF{"SENDFROM"}) : $CONF{"SENDFROM"};

	### フォーム内容メールの送信処理
	unless ($CONF{"DO_NOT_SEND"}) {
		my($del_list_ref, %attachdata) = sendmail_get_attachdata();
		my $format = $CONF{"MAIL_FORMAT_TYPE"} ? set_default_mail_format(type=>$CONF{"MAIL_FORMAT_TYPE"}) : $CONF{"FORMAT"};
		$format =~ s/##([^#]+)##/replace($1,"",\%FORM)/eg;
		### 2007-8-4 タイトルにもフォーム埋め込み可能とする
		my $subject = $CONF{"SUBJECT"};
		$subject =~ s/##([^#]+)##/replace($1,"",\%FORM)/eg;
		my %str = sendmail_mkstr(
			"subject"	=> $subject,
			"fromname"	=> $CONF{"SENDFROMNAME"},
			"mailstr"	=> $format,
			"credit"	=> $CONF{"copyright_mail_footer"},
			"charset"	=>$CONF{"CHARSET"},
			"attachdata"	=> \%attachdata,
		);
		### 2007-10-7 エンベロープアドレス対応
		my $envelope = $CONF{"ENVELOPE_ADDR_LINK"} ? $sendfrom : $CONF{"ENVELOPE_ADDR"};
		foreach my $mailto(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/,$CONF{"SENDTO"})) {
			sendmail(
				"charset"	=> $str{"charset"},
				"mailto"	=> $mailto,
				"cc"		=> $CONF{"CC"},
		                "bcc"		=> $CONF{"BCC"},
				"from"		=> $sendfrom,
				"subject"	=> $str{"subject"},
				"mailstr"	=> $str{"mailstr"},
				"fromname"	=> $str{"fromname"},
				"envelope"	=> $envelope,
			);
		}
	}

	### 自動返信メールの送信処理
	if ($CONF{"AUTO_REPLY"}) {
		my $format = $CONF{"REPLY_MAIL_FORMAT_TYPE"} ? set_default_mail_format("type"=>$CONF{"REPLY_MAIL_FORMAT_TYPE"}, "reply"=>1) : $CONF{"REPLY_FORMAT"};
		$format =~ s/##([^#]+)##/replace($1,"",\%FORM)/eg;
		### 2007-8-4 タイトルにもフォーム埋め込み可能とする
		my $subject = $CONF{"REPLY_SUBJECT"};
		$subject =~ s/##([^#]+)##/replace($1,"",\%FORM)/eg;
		my %str = sendmail_mkstr(
			"subject"	=> $subject,
			"fromname"	=> $CONF{"REPLY_SENDFROMNAME"},
			"mailstr"	=> $format,
			"credit"	=> $CONF{"copyright_mail_footer"},
			"charset"	=> $CONF{"REPLY_CHARSET"},
			"attachdata"	=> {},
		);
		### フォーム内容メールの送信処理
		foreach my $mailto(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/,$FORM{"EMAIL"})) {
			sendmail(
				"charset"	=> $str{"charset"},
				"mailto"	=> $mailto,
				"cc"		=> $CONF{"REPLY_CC"},
		                "bcc"		=> $CONF{"REPLY_BCC"},
				"from"		=> ($CONF{"REPLY_SENDFROM"} || $CONF{"SENDFROM"}),
				"subject"	=> $str{"subject"},
				"mailstr"	=> $str{"mailstr"},
				"fromname"	=> $str{"fromname"},
				"envelope"	=> $CONF{"REPLY_ENVELOPE_ADDR"},
			);
		}
	}

	### ファイル書き出し処理
	sendmail_file_output() if $CONF{"FILE_OUTPUT"};

	set_cookie($FORM{"CONFID"}, $CONF{"DENY_DUPL_SEND_MIN"}, 1)
	 if $CONF{"DENY_DUPL_SEND"};

	### セッションデータクリア
	$CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|, "");

	if (!$CONF{"THANKS_FLAG"}) {
		print qq|Location: $CONF{"THANKS"}\n\n|;
	} else {
		$CONF{"SUBJECT"} = html_output_escape($CONF{"SUBJECT"});

		output_form("THANKS") if $CONF{"THANKS_FLAG"} == 2;

		my $str;
		printhtml(qq|./tmpl/default/@{[ $CONF{"LANG"} or $CONF{"LANG_DEFAULT"} ]}/thanks.html|,
		 "CHARSET"=>($CONF{"THANKS_TMPL_CHARSET"} || "auto"),
		 (map { $_ => $CONF{$_} } keys %CONF),
		 "list" => get_formdatalist(),
		 map { $_ => replace($_,"html",\%FORM) } map { $_->[0] } @{$CONF{"COND"}});
	}
	exit;

}

sub sendmail_file_output {

	return unless @{$CONF{"OUTPUT_FIELDS"}};

	my %dt = get_datetime_for_file_output();
	$CONF{"OUTPUT_FILENAME"} =~ s/%([YMDHIS])/$dt{$1}/g;
	$CONF{"OUTPUT_FILENAME"} =~ s/##([^#]+)##/$FORM{$1}/g;
	$CONF{"OUTPUT_FILENAME"} =~ s#([^\da-zA-Z_.,-])#'%' . unpack('H2', $1)#eg;
	unless (-d qq|data/output/$FORM{"CONFID"}|) {
		mkdir(qq|data/output/$FORM{"CONFID"}|, 0777)
		 or error(get_errmsg("116", $CONF{"OUTPUT_FILENAME"}, $!));
	}
	open(my $fh, ">>", qq|./data/output/$FORM{"CONFID"}/$CONF{"OUTPUT_FILENAME"}|)
	 or error(get_errmsg("115", $CONF{"OUTPUT_FILENAME"}, $!));
	flock($fh, LOCK_EX);
	seek($fh, 0, 2);

	my %FORM2;
	foreach my $field(@{$CONF{"OUTPUT_FIELDS"}}) {
		$FORM{$field} =~ s/\r\n/\n/g;
		$FORM{$field} =~ s/\r/\n/g;
		if ($CONF{"OUTPUT_SEPARATOR"}) {
			$FORM{$field} =~ s/"/""/g;
			$FORM2{$field} = qq|"$FORM{$field}"|;
			$FORM2{$field} =~ s/\n/$CONF{"NEWLINE_REPLACE"} eq '' ? "\n" : $CONF{"NEWLINE_REPLACE"}/eg;
		} else {
			$FORM{$field} =~ s/\t+/ /g;
			$FORM2{$field} = $FORM{$field};
			$FORM2{$field} =~ s/\n/$CONF{"NEWLINE_REPLACE"}/g;
		}
		$FORM2{$field} =~ s/\!\!\!/$CONF{"FIELD_SEPARATOR"} eq '' ? " " : $CONF{"FIELD_SEPARATOR"}/eg;
	}
	print $fh join(($CONF{"OUTPUT_SEPARATOR"} ? "," : "\t"),
	 @FORM2{@{$CONF{"OUTPUT_FIELDS"}}}),"\n";
	close($fh);

}

sub sendmail_get_attachdata {

	my %attachdata;
	my @del_list;
	my %exists = ajax_file_check("thru" => 1);

	for my $fname(@{$CONF{"ATTACH_FIELDNAME"}}) {

		if ($exists{$fname}{"name"} ne "") {
			open(my $fh, "<", qq|./temp/$exists{$fname}{"filename"}|)
			 or error(get_errmsg("121", $!));
			$attachdata{$exists{$fname}{"name"}} = join("", <$fh>);
			close($fh);
			(my $f) = $exists{$fname}{"filename"} =~ /^([\da-zA-Z_.,%-]+)$/;
			push(@del_list, "./temp/$f");
		}
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
	my $boundary = "--".join("", map { ('0'..'9','a'..'f')[rand(16)] } 1..24);
	my $str;
	my %charset_conv = (
		"us-ascii" => "US-ASCII",
		"iso-8859-1" => "ISO-8859-1",
		"jis" => "ISO-2022-JP",
		"utf8" => "UTF-8",
		"sjis" => "Shift_JIS",
	);

	### 文字コード	コード変換 subject/fromname変換
	### -------------------------------------------
	### us-ascii	－		－
	### iso-8859-1	－		－
	### utf-8	－		○
	### sjis	○		○
	### jis		○		○
	### -------------------------------------------

	### 自動判定
	if ($opt{"charset"} eq "" or $opt{"charset"} eq "auto") {
		if ($opt{"subject"} =~ /^[\r\n\x20-\x7e]*$/ and $opt{"str"} =~ /^[\r\n\x20-\x7e]*$/ and $opt{"credit"} =~ /^[\r\n\x20-\x7e]*$/) {
			$opt{"charset"} = $charset_conv{"us-ascii"};
		} elsif ($opt{"subject"} =~ /^[\r\n\x20-\x7e\xa0-\xff]*$/ and $opt{"str"} =~ /^[\r\n\x20-\x7e\xa0-\xff]*$/ and $opt{"credit"} =~ /^[\x20-\x7e\xa0-\xff]*$/) {
			$opt{"charset"} = $charset_conv{"iso-8859-1"};
		} elsif (mojichk($opt{"subject"}) or mojichk($opt{"mailstr"}) or mojichk($opt{"credit"})) {
			$opt{"charset"} = $charset_conv{"utf8"};
			$opt{"subject"} = base64_subj($opt{"charset"}, $opt{"subject"});
			$opt{"fromname"} = base64_subj($opt{"charset"}, $opt{"fromname"})
			 if $opt{"fromname"} ne "";
		} else {
			$opt{"charset"} = $charset_conv{"jis"};
			$opt{"mailstr"} = Unicode::Japanese->new($opt{"mailstr"}, "utf8")->jis;
			$opt{"credit"} = Unicode::Japanese->new($opt{"credit"}, "utf8")->jis;
			$opt{"subject"} = base64_subj($opt{"charset"}, Unicode::Japanese->new($opt{"subject"}, "utf8")->jis);
			$opt{"fromname"} = base64_subj($opt{"charset"}, Unicode::Japanese->new($opt{"fromname"}, "utf8")->jis)
			 if $opt{"fromname"} ne "";
		}

	### 文字コード固定
	} else {
		if ($opt{"charset"} eq "utf8") {
			$opt{"charset"} = $charset_conv{"utf8"};
			$opt{"subject"} = base64_subj($opt{"charset"}, $opt{"subject"});
			$opt{"fromname"} = base64_subj($opt{"charset"}, $opt{"fromname"})
			 if $opt{"fromname"} ne "";
		} elsif ($opt{"charset"} eq "jis") {
			$opt{"charset"} = $charset_conv{"jis"};
			$opt{"mailstr"} = Unicode::Japanese->new($opt{"mailstr"}, "utf8")->jis;
			$opt{"credit"} = Unicode::Japanese->new($opt{"credit"}, "utf8")->jis;
			$opt{"subject"} = base64_subj($opt{"charset"}, Unicode::Japanese->new($opt{"subject"}, "utf8")->jis);
			$opt{"fromname"} = base64_subj($opt{"charset"}, Unicode::Japanese->new($opt{"fromname"}, "utf8")->jis)
			 if $opt{"fromname"} ne "";
		} elsif ($opt{"charset"} eq "sjis") {
			$opt{"charset"} = $charset_conv{"sjis"};
			$opt{"mailstr"} = Unicode::Japanese->new($opt{"mailstr"}, "utf8")->sjis;
			$opt{"credit"} = Unicode::Japanese->new($opt{"credit"}, "utf8")->sjis;
			$opt{"subject"} = base64_subj($opt{"charset"}, Unicode::Japanese->new($opt{"subject"}, "utf8")->sjis);
			$opt{"fromname"} = base64_subj($opt{"charset"}, Unicode::Japanese->new($opt{"fromname"}, "utf8")->sjis)
			 if $opt{"fromname"} ne "";
		} else {
			$opt{"charset"} = $charset_conv{$opt{"charset"}};
		}
	}

	if (keys %{$opt{"attachdata"}}) {
		$str .= <<STR;
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="$boundary"


--$boundary
Content-type: text/plain; charset=$opt{"charset"}

$opt{"mailstr"}
$opt{"credit"}
STR
	} else {
		$str .= <<STR;
MIME-Version: 1.0
Content-Transfer-Encording: 7bit
Content-type: text/plain; charset=$opt{"charset"}

$opt{"mailstr"}
$opt{"credit"}
STR
	}

	foreach my $filename(keys %{$opt{"attachdata"}}) {
#        my $content_type = $filename =~ /\.html?$/ ? "text/html" : "application/octet-stream";
		my $content_type = "application/octet-stream";
		my $encoding_type = $opt{"encoding"} eq "uuencode"
		 ? "X-uuencode" : "base64";
		my $attachdata = $opt{"encoding"} eq "uuencode"
		 ? uuencode($opt{"attachdata"}->{$filename}, $filename)
		 : base64($opt{"attachdata"}->{$filename});
		$str .= <<STR;
--$boundary
Content-Type: $content_type; name="$filename"
Content-Disposition: attachment;
 filename="$filename"
Content-Transfer-Encoding: $encoding_type

$attachdata
STR
	}

	$str .= "--$boundary--\n" if keys %{$opt{"attachdata"}};

	return %opt, "mailstr" => $str;

}

