
use strict;
use vars qw(%CONF %FORM %alt $q %ERRMSG $smtp);
use POSIX qw(SEEK_SET);
require "f_mailer_get_output_form.pl";

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

sub checkvalues {

	my %opt = @_;
	my @errmsg;
	my %condcheck = condcheck_init();
	my @checklist = map { $_->{"name"} } get_checklist();
	my %to_delete;
	my %exists = ajax_file_check("thru"=>1);

	### フィールドのグループ化
	### 暫定的にこの位置に入れる
	ext_sub0() if $CONF{"EXTFILE_EXIST"};

	my %group_flag;
	my %cond_hash = map { $_->[0]=>$_->[1] } @{$CONF{"COND"}};
	foreach (@{$CONF{"COND"}}) {
		my($f_name, $cond_hash) = @$_;
		$FORM{$f_name} = $FORM{$f_name};

		if ($CONF{"field_group_rev"}{$f_name}) {
			my @group_errmsg;
			my %errtype;
			next if $group_flag{$CONF{"field_group_rev"}{$f_name}}++;
			for my $group_field(@{$CONF{"field_group"}{$CONF{"field_group_rev"}{$f_name}}{"list"}}) {
				my($errmsg_ref, $to_delete_ref, $errtype_ref)
				 = checkvalues_condcheck(\%condcheck, $group_field, $cond_hash{$group_field}, "group"=>1);
				%errtype = (%errtype, %$errtype_ref);
				push(@group_errmsg, @$errmsg_ref) if @$errmsg_ref;
			}
			for my $key(grep { $errtype{$_} } @checklist) {
				push(@errmsg, set_errmsg(
					"key"=>$key,
					"f_name"=>$CONF{"field_group"}{$CONF{"field_group_rev"}{$f_name}}{"alt"},
					"str"=>$CONF{"errmsg"}{"required_input"},
				));
			}
			push(@errmsg, @group_errmsg) if @group_errmsg;
		} else {
			my($errmsg_ref, $to_delete_ref)
			 = checkvalues_condcheck(\%condcheck, $f_name, $cond_hash, "exists"=>($exists{$f_name}{"name"} ? 1 : 0));
			%to_delete = (%to_delete, %$to_delete_ref);
			push(@errmsg, @$errmsg_ref) if @$errmsg_ref;
		}
	}

	### 拡張コードの実行
	### エラーメッセージのリストを受け取ります。
	if ($CONF{"EXTFILE_EXIST"}) {
		my @xerrmsg = ext_sub();
		if (ref($xerrmsg[0])) {
			@xerrmsg = @{$xerrmsg[0]};
		}
		push(@errmsg, @xerrmsg) if @xerrmsg;
	}

	return @errmsg if $opt{"ajax"} == 1;
	error_formcheck(@errmsg) if @errmsg;


	### グループ指定した元のフィールドを削除
	### 代わりにグループ指定したフィールドを追加
	### グループ内で連結した文字列を生成

#	my @name_list_new;
#	%group_flag = ();
#	foreach (keys %to_delete) { delete $FORM{"${_}2"} }
#	for my $d (@{$CONF{"COND"}}) {
#		my($fname, $cond) = @$d;
#		if ($CONF{"field_group_rev"}{$fname}) {
#			next if $group_flag{$CONF{"field_group_rev"}{$fname}}++;
#			push(@name_list_new, $CONF{"field_group_rev"}{$fname});
#			my $vchk = 0;
#			for (@{$CONF{"field_group"}{$CONF{"field_group_rev"}{$fname}}{"list"}}) {
#				$vchk++ if $fname ne "";
#			}
#			$FORM{$CONF{"field_group_rev"}{$fname}}
#			 = join($CONF{"field_group"}{$CONF{"field_group_rev"}{$fname}}{"constr"},
#			  @FORM{@{$CONF{"field_group"}{$CONF{"field_group_rev"}{$fname}}{"list"}}})
#			 if $vchk;
#			$alt{$CONF{"field_group_rev"}{$fname}} = $CONF{"field_group"}{$CONF{"field_group_rev"}{$fname}}{"alt"};
#			next;
#		}
#	}
#
#	$CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|, \%FORM);

}

sub checkvalues_condcheck {

	my($condcheck, $f_name, $cond_hash, %opt) = @_;
	my @errmsg;
	my %errtype;
	my %to_delete;

	foreach my $key(@{$condcheck->{"__order"}}) {
		next if $key eq 'alt' or $key eq 'attach' or $key eq 'type';
		next unless $cond_hash->{$key};
#		$to_delete{$f_name} = $f_name."2" if $key eq "compare";
		($FORM{$f_name}, my @errmsg_) = &{$condcheck->{$key}}(
		 $f_name,
		 $alt{$f_name},
		 $FORM{$f_name},
		 ($key eq "compare" ? $FORM{"${f_name}2"} : $cond_hash->{$key}),
		 $cond_hash->{"type"},
		 $cond_hash->{"d_only"},
		 $opt{"exists"}, ### 添付ファイルアップロード有無
		);
		if (@errmsg_) {
			if ($opt{"group"} and $key !~ /^(?:min|max)$/) {
				$errtype{$key} = 1;
			} else {
				push(@errmsg, map { [ $f_name, $_ ] } @errmsg_);
			}
		}
	}
	$to_delete{$f_name} = 1 if $opt{"group"};
	return \@errmsg, \%to_delete, \%errtype;

}

sub comma {

	my $num = shift;
	1 while $num =~ s/(.*\d)(\d\d\d)/$1,$2/;
	$num or 0;

}

sub conf_read {

	my ($confid, $json, $p) = @_;

	if ($confid) {
		if ($confid !~ /^\d{6}|sample$/) {
			error(get_errmsg("470"));
		}
		my $file = get_conffile_by_id($confid);
		if (-e "data/conf/$file.json") {
			open(my $fh, "<", "data/conf/$file.json") or error(get_errmsg("612", $!, $confid));
			$json = <$fh>;
			close($fh);
		}
	} elsif (! $json) {
		error(get_errmsg("612", $!, $confid));
	}

	return %{ json_decode($json) };
}

sub conf_read_to_temp {

	my ($confid, $json, $p) = @_;

	my %conf = conf_read($confid, $json, $p);

	$conf{"ATTACH_EXT"} = join(" ", @{$conf{"ATTACH_EXT"}});
	$conf{"cond"} = join(",", map { $_->[0] } @{$conf{"COND"}});
	my @check_list = get_checklist();
	for my $i(0..@{$conf{"COND"}}-1) {
		my $fname = $conf{"COND"}[$i][0];
		$conf{qq|_cond_type_$fname|} = $conf{"COND"}[$i][1]{"type"};
		for my $row(@check_list) {
			$conf{qq|_cond_$row->{"name"}_$fname|} = $conf{"COND"}[$i][1]{$row->{"name"}};
		}
	}
	for my $i(1..@{$conf{"OUTPUT_FIELDS"}}) {
		$conf{"order_".$conf{"OUTPUT_FIELDS"}[$i-1]} = $i;
	}
	$conf{"OUTPUT_FIELDS"} = join(",", @{$conf{"OUTPUT_FIELDS"}});
	$conf{"DO_NOT_SEND"} ||= 0;
	$conf{"cond"} = join(",", map { $_->[0] } @{$conf{"COND"}});
	return %conf;

}

sub conf_write {

	my ($confid, $file, %d) = @_;
	if ($confid !~ /^\d{6}|sample$/) {
		error(get_errmsg("470"));
	}

	$d{"ATTACH_EXT"} = [split(/[,\s]+/, $d{"ATTACH_EXT"})];
	$d{"OUTPUT_FIELDS"} = [ split(/,/, $d{"OUTPUT_FIELDS"}) ];
	$d{"ATTACH_FIELDNAME"} = [];

	my @check_list = get_checklist();
	my @confmeta = get_confmeta();
	my %skip = map { $_->[0] => 1 } @confmeta;
	$d{"COND"} = [];
	my $i = 0;
	for my $fname(split(/,/, $d{"cond"})) {
		$d{"COND"}[$i][0] = $fname;
		if (! $skip{$fname}) {
			$d{"COND"}[$i][1]{"type"} = $d{qq|_cond_type_$fname|};
			delete $d{qq|_cond_type_$fname|};
		}
		push(@{$d{"ATTACH_FIELDNAME"}}, $fname) if $d{"_cond_attach_$fname"};
		for my $row(@check_list) {
			next if ($skip{$fname} and $row->{"name"} ne "alt");
			if ($d{qq|_cond_$row->{"name"}_$fname|} ne "") {
				$d{"COND"}[$i][1]{$row->{"name"}} = $d{qq|_cond_$row->{"name"}_$fname|};
			}
			delete $d{qq|_cond_$row->{"name"}_$fname|};
		}
		$i++;
	}
	### labelと英大文字で始まるキー以外のデータは削除
	for (keys %d) {
		next if ($_ eq "label" or /^[A-Z]/);
		delete $d{$_};
	}
	open(my $fh, ">", "data/conf/$file.json") or error(get_errmsg("620", $!, $confid));
	(my $json = json_encode(\%d)) =~ s/\\r\\n/\\n/g;
	print $fh $json;
	close($fh);
}

sub data_convert {

	my %form = @_;

	my $code = $CONF{"FORM_TMPL_CHARSET"} eq "auto"
	 ? ($form{"GETCODE"} ? Unicode::Japanese->new($form{"GETCODE"})->getcode() : "utf8")
	 : $CONF{"FORM_TMPL_CHARSET"};

	my %form2;
	while (my($key, $value) = each %form) {
		$key = Unicode::Japanese->new($key, $code)->get if $code ne "utf8";
		$value = Unicode::Japanese->new($value, $code)->get if $code ne "utf8";
		$form2{$key} = $value;
	}

	return %form2;

}

sub decoding {

	my $q = shift;
	my %form;
	foreach my $name($q->param()) {
		foreach my $each($q->param($name)) {
			if (defined($form{$name})) {
				$form{$name} = join('!!!', $form{$name}, $each);
			} else {
				$form{$name} = $each . "";
			}
		}
	}
	return %form;

}

sub error {

	error_(@_) unless $CONF{"LANG"};

	output_form("ERROR", \@_) if $CONF{"ERROR_FLAG"};

	my $errmsg = mk_errmsg(\@_);

	printhtml(qq|./tmpl/default/@{[ $CONF{"LANG"} or $CONF{"LANG_DEFAULT"} ]}/error.html|,
	 "CHARSET"=> "sjis",
	 (map { $_ => $CONF{$_} } keys %CONF),
	 "errmsg" => $errmsg,
	);
	 exit;

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

	my $confid = shift;
	open(my $fh, "<", "data/conflist.json")
	 or error_(get_errmsg("210", $!));
	my $json = json_decode(<$fh>);
	close($fh);
	for my $d(@$json) {
		return $d->{"file"} if $d->{"id"} eq $confid;
	}
	error_(get_errmsg("211", $confid));

}

sub get_conflist {

	my $conflist;
	my @list;
	my $json = conflist_read();
	for my $d(@$json) {
		$conflist .= qq{<option value="$d->{"id"}">$d->{"label"}($d->{"id"})</option>\n};
		push(@list, $d);
	}
	return wantarray ? @list : $conflist;

}

sub get_confmeta {

	open(my $fh, "<", "data/confmeta.json") or error(get_errmsg("221", $!));
	my $confmeta = json_decode(<$fh>);
	close($fh);
	return @$confmeta;
}

sub get_cookie {

	my $cookie_name = shift;
	error(get_errmsg("230")) if !$cookie_name;
	foreach (split(/; /, $ENV{"HTTP_COOKIE"})) {
		my($name, $value) = split(/=/);
		if ($name eq $cookie_name) {
			my @cookie_data = split(/\!\!\!/, $value);
			return wantarray ? @cookie_data : $cookie_data[0];
		}
	}
	return undef;

}
sub get_data_from_keyfile {

	my($confid, %opt) = @_;

	unless (-e "data/key/$confid/keys_$confid.csv") {
		error(get_errmsg("011"));
	}
	open(my $fh, "<", "data/key/$confid/keys_$confid.csv");
	chomp(my $h = <$fh>);
	my @f = split(/,/, $h);
	my $exists = 0;
	while (<$fh>) {
		chomp;
		my %d;
		@d{@f} = split(/,/);
		return %d if ($opt{"ID"} ne "" and $d{"ID"} eq $opt{"ID"} or $opt{"KEY"} ne "" and $d{"KEY"} eq $opt{"KEY"});
	}
	return;
}

sub get_datetime {

	my $time = shift || time;

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

	my %ignore_name = map { $_ => 1 } reserved_words(), reserved_words3();
	my $list;
	for my $d(@{$CONF{"COND"}}) {
		my ($fname, $cond) = @$d;
		next if $ignore_name{$fname};
		my $name_dsp = $cond->{"alt"} || $fname;
		$list .= <<STR;
<tr>
	<th class="l">$name_dsp</th>
	<td>##$fname##</td>
</tr>
STR
	}

	$list =~ s/##([^#]+)##/replace($1,'html', \%FORM)/eg;
	$list;

}

sub get_sid {
	## Digest::MD5必要
	return md5_hex(time . $$);
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
		(my $filename_enc_clean) = $filename_enc =~ /^([^\/]+)$/;
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

sub is_email {

	return $_[0] =~ /^[-_.!*a-zA-Z0-9\/&+%\#]+\@[-_.a-zA-Z0-9]+\.(?:[a-zA-Z]{2,4})$/ ? 1 : 0;
 
}

sub is_url {

	my $url = shift;
	return 1 if $url =~ m|^s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+$|;
	return 0;

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

### 2019-04-12 PHPライクなJSONデータ対応
sub json_decode {
	my $json = shift;
	my $decoded;
	eval { $decoded = from_json($json); };
	if ($@) {
		error($@, $json, caller());
	}
	return $decoded;  # JSONデータ
}

sub json_encode {
	my $d = shift; # ハッシュまたは配列のリファレンス
#	return JSON->new->ascii(1)->utf8(1)->encode($d);
	return to_json($d);
}

sub json_output {
	my $d = shift;
	print "Content-type: text/json\n\n";
	print json_encode($d);
	exit;
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

	my $errmsg_li_style = $CONF{"ERRMSG_STYLE_LI"} ne "" ? qq| style="$CONF{"ERRMSG_STYLE_LI"}"| : "";
	my $errmsg_li_class = $CONF{"ERRMSG_STYLE_LI_CLASS"} ne "" ? qq| class="$CONF{"ERRMSG_STYLE_LI_CLASS"}"| : "";
	my $errmsg_ul_style = $CONF{"ERRMSG_STYLE_UL"} ne "" ? qq| style="$CONF{"ERRMSG_STYLE_UL"}"| : "";
	my $errmsg_ul_class = $CONF{"ERRMSG_STYLE_UL_CLASS"} ne "" ? qq| class="$CONF{"ERRMSG_STYLE_UL_CLASS"}"| : "";
	my $errmsg_ul_id = $CONF{"ERRMSG_STYLE_UL_ID"} ne "" ? qq| id="$CONF{"ERRMSG_STYLE_UL_ID"}"| : "";

	# @$errmsg_refでループ
	# ref == ARRAYのとき
	# 	FORM_TMPL_ERRMSG_DISPLAY == 2 のとき、入力欄に表示
	# 		id="f_mailer_errmsg_label_bg-[フィールド名]" に addCLass "f_mailer_errmsg_label_bg"
	# 		id="f_mailer_errmsg_bg-[フィールド名]" に addCLass "f_mailer_errmsg_bg"
	# 		name=[フィールド名] に addCLass "f_mailer_errmsg_border"　※赤枠をつける
	# 		id="f_mailer_errmsg-[フィールド名]" の中に addCLass "f_mailer_errmsg"、 メッセージテキストを入れる
	#		jQuery必須
	#	
	my @errmsg_list;
	my @sel;
	my $errmsg_js = "";
	for my $d (@$errmsg_ref) {
		if (ref $d eq "ARRAY") {
			my ($f_name, $errmsg) = @$d;
			$errmsg = h($errmsg);
			if ($CONF{"FORM_TMPL_ERRMSG_DISPLAY"} == 2) {
				push(@sel, $f_name);
				$errmsg_js .= qq|\t\$("#f_mailer_errmsg-$f_name").text("$errmsg");\n|;
			} else {
				push(@errmsg_list, $errmsg);
			}
		} else {
			push(@errmsg_list, $d);
		}
	}
	if (@sel) {
		$errmsg_js .= qq|\t\$("| . join(",", map { "#f_mailer_errmsg_label_bg-$_" } @sel) . qq|").addClass("f_mailer_errmsg_label_bg");\n|;
		$errmsg_js .= qq|\t\$("| . join(",", map { "#f_mailer_errmsg_bg-$_" } @sel) . qq|").addClass("f_mailer_errmsg_bg");\n|;
		$errmsg_js .= qq|\t\$("| . join(",", map { "[name=$_]" } @sel) . qq|").addClass("f_mailer_errmsg_border");\n|;
		$errmsg_js .= qq|\t\$("| . join(",", map { "#f_mailer_errmsg-$_" } @sel) . qq|").addClass("f_mailer_errmsg");\n|;
	}
	if ($errmsg_js ne "") {
		$errmsg_js = qq|\n<script type="text/javascript">\n<!--\n\$(function () {\n$errmsg_js});\n// -->\n</script>\n|;
	}
	my $errmsg = "";
	if (@errmsg_list) {
		$errmsg = qq|<ul$errmsg_ul_style$errmsg_ul_class$errmsg_ul_id>\n| . join("\n", map { qq|<li$errmsg_li_style$errmsg_li_class>$_</li>| } map { h($_) } @errmsg_list) .qq|\n</ul>|;
	}
	return $errmsg . $errmsg_js;

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

sub output_form {

	require "f_mailer_get_output_form.pl";

	my($phase, $errmsg_ref) = @_;
#die "$phase,$errmsg," , caller();
#d(mk_errmsg($errmsg_ref));

	my($code, $htmlstr) = printhtml_getpage(($CONF{"${phase}_TMPL_CHARSET"} || "auto"), {
		"filename" => $CONF{"${phase}_TMPL"},
		"errmsg" => ($errmsg_ref || []),
	});

	my %d;
	if (ref $errmsg_ref) {
		if (ref $CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|) eq "HASH") {
			%d = %{ $CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|) };
		}
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

sub printhtml {

	my($filename, %tr) = @_;

	my $charset;
	if (exists $tr{"CHARSET"}) {
		$charset = $tr{"CHARSET"};
		delete $tr{"CHARSET"};
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
		$opt{"filename"} =~ s/##([^#]+)##/uri_escape($FORM{$1})/eg;
		$htmlstr = encode_utf8(get($opt{"filename"}));
	} else {
		open(my $fh, "<", $opt{"filename"}) or error_(get_errmsg("261", $@, $opt{"filename"}));
		$htmlstr = join("", <$fh>);
		close($fh);
	}
	my $code;
	if ($ENV{"SCRIPT_FILENAME"} =~ m#admin# or $opt{filename} =~ m#\./tmpl/default/#) {
		$charset = "utf8";
	} else{
		my $code = $charset || Unicode::Japanese->new($htmlstr)->getcode() || "utf8";
		$code = "utf8" if $code =~ /utf/;
		$charset = $code if $charset eq "auto";
	### 2013-10-30 常にコード変換する(utf-8→utf-8の文字化け回避)
		$htmlstr = Unicode::Japanese->new($htmlstr, $charset)->get if $charset ne "utf8";
	}
	$htmlstr =~ s/<!-- header -->/$opt{"header"}/;
	$htmlstr =~ s/<!-- footer -->/$opt{"footer"}/;
	$htmlstr =~ s/<!-- errmsg -->/mk_errmsg($opt{"errmsg"})/e;
	######################################################################
	### 下の処理を変更しないでください。                               ###
	### 各ページのフッタ部分の著作権表示をなくしたい場合は、届け出の上 ###
	### 利用規約第10条第5項の料金をお支払いいただきます。              ###
	### http://www.psl.ne.jp/lab/copyright.html                        ###
	######################################################################
	$htmlstr =~ s/##COPYRIGHT##/$ENV{"SCRIPT_FILENAME"} =~ m#admin# ? $CONF{"copyright_html_footer_admin"} : $CONF{"copyright_html_footer"}/eg;
	$htmlstr =~ s/##prod_name##/$CONF{"prod_name"}/g;
	$htmlstr =~ s/##version##/$CONF{"version"}/g;
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

	if ($ENV{"REMOTE_HOST"} eq $ENV{"REMOTE_ADDR"} or $ENV{"REMOTE_HOST"} eq '') {
		gethostbyaddr(pack('C4', split(/\./, $ENV{"REMOTE_ADDR"})), 2) or $ENV{"REMOTE_ADDR"};
	} else {
		$ENV{"REMOTE_HOST"};
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

	$value eq '' ? $CONF{"BLANK_STR"} : $value;

}

sub reserved_words {

	qw(CONF CONFID TEMP VALUES CREDIT SEND_FORCED GETCODE DUMMY __token __token_ignore);
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

	$opt{"envelope"} = qq|-f $opt{"envelope"}| if $opt{"envelope"};

	if ($opt{"fromname"}) {
		$opt{"fromname"} = qq{"$opt{"fromname"}" <$opt{"from"}>};
	} else {
		$opt{"fromname"} = $opt{"from"};
	}
	my $date = get_datetime_for_mailheader(time);

	### Net::SMTPモード
	if ($CONF{"SENDMAIL_FLAG"}) {

		eval qq{use Net::SMTP};
		error_("Net::SMTPがインストールされていません。: $@") if $@;
		if ($CONF{"USE_SMTP_AUTH"}) {
			eval qq{use MIME::Base64};
			error_("MIME::Base64がインストールされていません。: $@") if $@;
			eval qq{use Authen::SASL};
			error_("Authen::SASLがインストールされていません。: $@") if $@;
		}

		$smtp ||= Net::SMTP->new($CONF{"SMTP_HOST"})
		 or error("Net::SMTPで$CONF{SMTP_HOST}へ接続できませんでした。: $!");
		my $date = get_datetime_for_mailheader(time);

		if ($CONF{"USE_SMTP_AUTH"}) {
			$smtp->auth($CONF{"SMTP_AUTH_ID"}, $CONF{"SMTP_AUTH_PASSWD"})
			 or do { $smtp->quit; error('authメソッド失敗: ' .$!); };
		}
		$smtp->mail($opt{"envelope"} || $opt{"from"});
		$smtp->to($opt{"mailto"});
		if ($opt{"cc"}) {
			$smtp->cc(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $opt{"cc"}));
		}
		if ($opt{"bcc"}) {
			$smtp->bcc(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $opt{"bcc"}));
		}
		$smtp->data();
		$smtp->datasend("Date: $date\n");
		$smtp->datasend(qq|To: $opt{"mailto"}\n|);
		if ($opt{"cc"}) {
			$smtp->datasend("Cc: ". join(",\n\t", split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $opt{"cc"})). "\n");
		}
		if ($opt{"bcc"}) {
			$smtp->datasend("Bcc: ". join(",\n\t", split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $opt{"bcc"})). "\n");
		}
		if ($opt{"reply_to"}) {
			$smtp->datasend("Reply-To: ". $opt{"reply_to"}. "\n");
		}
		$smtp->datasend(qq|From: $opt{"fromname"}\n|);
		$smtp->datasend(qq|Subject: $opt{"subject"}\n|);
		$smtp->datasend($opt{"mailstr"});
		$smtp->dataend();

	### sendmailモード
	} else {

		open(my $mail, qq#| $CONF{"SENDMAIL"} -t#)
			 or error(get_errmsg("270", $!));
		print $mail "Date: $date\n";
		print $mail qq|To: $opt{"mailto"}\n|;
		if ($opt{"cc"}) {
			print $mail "Cc: ", join(",\n\t", split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $opt{"cc"})), "\n";
		}
		if ($opt{"bcc"}) {
			print $mail "Bcc: ", join(",\n\t", split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $opt{"bcc"})), "\n";
		}
		if ($opt{"reply_to"}) {
			print $mail "Reply-To: ", $opt{"reply_to"}, "\n";
		}
		print $mail qq|From: $opt{"fromname"}\n|;
		print $mail qq|Subject: $opt{"subject"}\n|;
		print $mail $opt{"mailstr"};
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

	my($cookie_name, $cookie_data, $opt) = @_;
	### 2021-01-14 PATH_INFOがあってもf_mailer.cgiの位置にパスを統一するためにパスを取得
	(my $cookie_path) = $ENV{"REQUEST_URI"} =~ m#^(.*)/\Q$0\E#;
	$opt = {
		"Path" => $cookie_path,
		"Secure" => 1,
		"HttpOnly" => 1,
		"SameSite" => "Lax",
		ref $opt eq "HASH" ? %$opt : ()
	};
	if (ref $cookie_data eq "ARRAY") {
		$cookie_data = join("!!!", @$cookie_data);
	}
	my @opt;
	push(@opt, "$cookie_name=$cookie_data");
	push(@opt, "Expires=". get_datetime_for_cookie($opt->{"Expires"})) if $opt->{"Expires"};
	push(@opt, "Domain=". $opt->{"Domain"}) if $opt->{"Domain"};
	push(@opt, "Path=". $opt->{"Path"}) if $opt->{"Path"};
	push(@opt, "SameSite=". $opt->{"SameSite"}) if $opt->{"SameSite"};
	push(@opt, "Secure") if $opt->{"Secure"};
	push(@opt, "HttpOnly") if $opt->{"HttpOnly"};
	print "Set-Cookie: ", join("; ", @opt), "\n";

}

sub set_default_mail_format {

	my %opt = @_;
	my($mark, $sepr, $oft) = $opt{"reply"}
	 ? @CONF{qw(REPLY_MARK REPLY_SEPR REPLY_OFT)}
	 : @CONF{qw(MARK SEPR OFT)};

	my $default_mail_format = <<STR;
------------------------------------------------------------
$CONF{"TITLE"}
------------------------------------------------------------
STR

	my $indent = (" " x length($mark));
	my %skip = map { $_ => 1 } reserved_words(), reserved_words3();
	for my $d(@{$CONF{"COND"}}) {
		my ($fname, $cond) = @$d;
		next if $CONF{"BLANK_SKIP"} and $FORM{$fname} eq '';
		next if $skip{$fname};
		my $name_dsp = $cond->{"alt"} || $fname;
		my $value_dsp = $opt{"attach_url"}{$fname} || $FORM{$fname};

		if ($opt{"type"} == 1) {
			$value_dsp =~ s/\!\!\!|\n/\n$indent/g;
			$default_mail_format .= "$mark$name_dsp$sepr\n$indent$value_dsp\n\n";
		} elsif ($opt{"type"} == 2) {
			$value_dsp =~ s/\!\!\!/ /g;
			$value_dsp =~ s/\n/\n$indent/g;
			$default_mail_format .= "$mark$name_dsp$sepr$value_dsp\n";
		} else {
			$value_dsp =~ s/\!\!\!/ /g;
			$value_dsp =~ s/\n/"\n".(" " x ($oft+length($sepr)))/eg;
			$default_mail_format .= sprintf("%-${oft}s","$mark$name_dsp") . "$sepr$value_dsp\n";
		}
	}

	$default_mail_format .= <<STR;
------------------------------------------------------------
送信日時    ：$FORM{"NOW_DATE"}
接続元ホスト：$FORM{"REMOTE_HOST"}
使用ブラウザ：$FORM{"USER_AGENT"}
------------------------------------------------------------
STR

	return $default_mail_format;

}

sub set_errmsg {

	my %opt = @_;
	my $str = $CONF{"errmsg"}{$opt{"key"}};
	$opt{"str"} =~ s/##f_name##/$opt{f_name}/g;
	$str =~ s/##$_##/$opt{$_}/g for qw(f_name cond cond2 eval str);
	return $str;

}

sub set_errmsg_init {

	%ERRMSG = load_errmsg($CONF{"LANG"});

	### 2008-6-12 暫定的にこの位置に指定
	### 管理画面で設定できるようにする
	### ##f_name##…フィールド名
	### ##cond##…min/max条件で、上限あるいは下限値
	### ##eval##…regex/regex2条件で、evalに失敗したときに返される$@の値
	### ##str##…required条件で、
	###           radio/checkbox/selectは「required_choose」
	###           その他は「required_input」
	$CONF{"errmsg"} = {
		"compare"		=> get_errmsg("290",  "##f_name##"),
		"d_only"		=> get_errmsg("291",  "##f_name##"),
		"email"			=> get_errmsg("292",  "##f_name##"),
		"hira_only"		=> get_errmsg("293",  "##f_name##"),
		"kata_only"		=> get_errmsg("294",  "##f_name##"),
		"len_max"		=> get_errmsg("295",  "##f_name##", "##cond2##"),
		"num_max"		=> get_errmsg("296",  "##f_name##", "##cond##"),
		"max"			=> get_errmsg("297",  "##f_name##", "##cond##"),
		"len_min"		=> get_errmsg("298",  "##f_name##", "##cond##"),
		"num_min"		=> get_errmsg("299",  "##f_name##", "##cond##"),
		"min"			=> get_errmsg("300",  "##f_name##", "##cond##"),
		"regex"			=> get_errmsg("292",  "##f_name##"),
		"regex2"		=> get_errmsg("292",  "##f_name##"),
		"regex_eval_error"	=> get_errmsg("301",  "##f_name##", "##eval##"),
		"required"		=> get_errmsg("302",  "##f_name##", "##str##"),
		"required_choose"	=> get_errmsg("303"),
		"required_input"	=> get_errmsg("304"),
		"required_upload"	=> get_errmsg("305"),
		"url"			=> get_errmsg("292",  "##f_name##"),
	};

}

sub setalt {

	my %alt;
	foreach (@{$CONF{"COND"}}) { $alt{$_->[0]} = $_->[1]->{"alt"}; }
	return %alt;
}

sub setver {
##############################################
###このサブルーチンは変更しないでください。###
##############################################
	my %PROD = (
		prod_name => q{FORM MAILER},
		version   => q{0.8pre210825},
		a_email   => q{info@psl.ne.jp},
		a_url     => q{https://www.psl.ne.jp/},
		copyright => q{&copy;1997-2021},
		copyright2 => q{(c)1997-2021},
	);
	chomp($PROD{"copyright_html_footer"} = <<STR);
<a href="$PROD{"a_url"}" target="_blank"><strong>$PROD{"prod_name"} v$PROD{"version"}</strong></a>
STR
	chomp($PROD{"copyright_html_footer_admin"} = <<STR);
<strong>$PROD{"prod_name"} v$PROD{"version"}</strong>
$PROD{"copyright"} <a href="$PROD{"a_url"}" onclick="this.target='_blank'">Perl Script Laboratory</a> All rights reserved.
STR

	chomp($PROD{"copyright_mail_footer"} = <<STR);
----
$PROD{"copyright2"} $PROD{"prod_name"} v$PROD{"version"}
$PROD{"a_url"}
STR
##############################################
###              ここまで                  ###
##############################################
	return %PROD;

}

sub sysconf_read {

	open(my $fh, "<", "data/sysconf.json") or error(get_errmsg("621", $!));
	my $json = <$fh>;
	close($fh);
	return %{ json_decode($json) };

}

### CSRF対策 トークン発行処理
sub token_publish {

	my $id = shift or error(caller());

	if ($CONF{"CSRF_TOKEN"}) {
		if ($ENV{"REQUEST_METHOD"} eq "POST" and ! $FORM{"__token_ignore"}) {
			if (! exists $FORM{"__token"}) {
				error(get_errmsg("090"));
			}
			if ($FORM{"__token"} ne $CONF{"session"}->param("__token-$id")) {
#				error(get_errmsg("091").qq|$FORM{"__token"} :: |.$CONF{"session"}->param("__token"));
				error(get_errmsg("091"));
			}
		}
		if (! $FORM{"__token_ignore"}) {
			$CONF{"session"}->param("__token-$id", $CONF{"__token"});
			$FORM{"__token"} = $CONF{"__token"};
		}
	}
	set_cookie("CGISESSID".($id eq "admin" ? "_ADMIN" : ""), $CONF{"session"}->id());
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
