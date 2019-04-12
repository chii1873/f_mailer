
use strict;
#use utf8;
use vars qw(%CONF %FORM %alt $q);

sub conf_to_temp {

	my %conf = @_;
	if ($conf{COND}) {
		my %skip = map { $_ => 1 } reserved_words3();
		my @cond;
		my @checklist = get_checklist();
		foreach my $i(0..$#{$conf{COND}}) {
			my $f = $conf{COND}[$i][0];
			push(@cond, $f) unless $skip{$f};
			$conf{"_cond_type_$f"} = $conf{COND}[$i][1]{type};
			foreach (@checklist) {
				$conf{"_cond_$_->{name}_$f"} = $conf{COND}[$i][1]{$_->{name}};
			}
		}
		$conf{cond} = join(",", @cond);
		delete $conf{COND};
	}
	if ($conf{ATTACH_EXT}) {
		$conf{ATTACH_EXT} = join(",", @{$conf{ATTACH_EXT}});
	}
	if ($conf{OUTPUT_FIELDS}) {
		my $cnt;
		$conf{"order_$_"} = ++$cnt for @{$conf{OUTPUT_FIELDS}};
	}

	%conf;

}

sub gen_conffilename {

	my $digit = shift || 6;
	while (1) {
		my $sid = join("", map { (0..9)[rand(10)] } (1..$digit));
		return $sid unless -e "data/conf/$sid.pl";
	}

}

sub get_conffields {

	open(my $fh, "<", "./data/conffields.txt")
	 or error(get_errmsg("600", $!));
	chomp(my @fields = <$fh>);
	close($fh);
	@fields;

}

sub get_langlist {

	if (! -e "./data/errmsg_ja.txt") {
		error(get_errmsg("601"));
	}
	my @list = (["ja", "日本語"]);
	opendir(my $dh, "./data") or error(get_errmsg("602", $!));
	foreach (sort grep(/^errmsg_[a-z]{2}\.txt$/, readdir($dh))) {
		(my $lang) = /^errmsg_([a-z]{2})\.txt$/;
		next if $lang eq "ja";
		open(my $fh, "<", "./data/$_") or error(get_errmsg("603", $_, $!));
		chomp(my $lang_dsp = <$fh>);
		push(@list, [$lang, $lang_dsp]);
	}
	closedir($dh);
	return @list;

}

sub get_langlist_select {

	my $lang_sel = shift;

	my $list;
	for (get_langlist()) {
		my ($lang, $lang_dsp) = @$_;
		my $sel = $lang_sel eq $lang ? q|selected="selected"| : "";
		$list .= qq|<option value="$lang" $sel>($lang)$lang_dsp</option>\n|;
	}
	return $list;

}


sub mk_conffile {

	my %conf = @_;
	if ($conf{conf_id}) {
		$conf{conffile} = get_conffile_by_id($conf{conf_id});
	} else {
		$conf{conffile} = gen_conffilename() . ".pl";
		$conf{conf_id} = gen_conffilename();
	}

	my $date = get_datetime(time);
	($conf{conffile}) = $conf{conffile} =~ /^([\w\.]+)$/;

	unless (-e "./data/confext/ext_$conf{conffile}") {
		open(my $fh, ">", "./data/confext/ext_$conf{conffile}")
		 or error(get_errmsg("610", $!));
		print $fh <<STR;
#
# $CONF{prod_name} v$CONF{version} 拡張設定ファイル
# $CONF{copyright2} Perl Script Laboratory All rights reserved.
#
# ext_$conf{conffile}
#
# このファイルはプログラムによって自動生成されました。
# 生成日時: $date

#use utf8;
#package ext;

sub ext_sub0 { }

### (11)付加的に実行したいコード1
### サブルーチン内でグローバル変数を使用できます(パッケージ名に注意)
### エラーメッセージのリストを戻り値に指定するとエラーページに遷移します。
### このサブルーチンは入力値チェックの一番最後に実行されます。
sub ext_sub {

	my \@errmsg;


	return \@errmsg;

}

### (12)付加的に実行したいコード2
### サブルーチン内でグローバル変数を使用できます(パッケージ名に注意)
### エラーメッセージのリストを戻り値に指定するとエラーページに遷移します。
### このサブルーチンはメール送信の直前に実行されます。
sub ext_sub2 {

	my \@errmsg;


	return \@errmsg;

}

1;
STR
		close($fh);
	}

	open(my $fh, ">", "data/conf/$conf{conffile}")
	 or error(get_errmsg("611", $!));
	print $fh <<STR;
#
# $CONF{prod_name} v$CONF{version} 設定ファイル
# $CONF{copyright2} Perl Script Laboratory All rights reserved.
#
# $conf{conffile}
#
# このファイルはプログラムによって自動生成されました。
# 生成日時: $date

#use utf8;
package conf;

 sub conf {

	my %conf;

STR

	my @list = split(/,/, $conf{cond});
	my @checklist = get_checklist();
	my $condstr;
	my $condcnt = 0;
	foreach my $f(@list) {
		$condstr .= qq|    chomp(\$conf{COND}[$condcnt][0] = <<'_STR_COND_');\n$f\n_STR_COND_\n|;
		$condstr .= qq|    chomp(\$conf{COND}[$condcnt][1]{type} = <<'_STR_COND_');\n$conf{"_cond_type_$f"}\n_STR_COND_\n|;
		foreach (@checklist) {
			$condstr .= qq|    chomp(\$conf{COND}[$condcnt][1]{$_->{name}} =<<'_STR_COND_');\n$conf{"_cond_$_->{name}_$f"}\n_STR_COND_\n| if $conf{"_cond_$_->{name}_$f"} ne "";
			delete $conf{"_cond_$_->{name}_$f"};
		}
		$condcnt++;
	}
	foreach my $f(qw(SERIAL REMOTE_HOST REMOTE_ADDR USER_AGENT NOW_DATE)) {
		$condstr .= qq|    chomp(\$conf{COND}[$condcnt][0] = <<'_STR_COND_');\n$f\n_STR_COND_\n|;
		$condstr .= qq|    chomp(\$conf{COND}[$condcnt][1]{alt} = <<'_STR_COND_');\n$conf{"_cond_alt_$f"}\n_STR_COND_\n|;
		$condcnt++;
	}

	foreach ("label", get_conffields()) {
		if ($_ eq "COND") {
			print $fh $condstr;
		} elsif ($_ eq "ATTACH_FIELDNAME") {
			print $fh q{    $conf{ATTACH_FIELDNAME} = [qw(},
			 $conf{ATTACH_FIELDNAME}, qq{)];\n};
		} elsif ($_ eq "ATTACH_EXT") {
			print $fh q{    $conf{ATTACH_EXT} = [qw(},
			 join(" ", split(/,/, $conf{ATTACH_EXT})),
			 qq{)];\n};
		} elsif ($_ eq "OUTPUT_FIELDS") {
			print $fh q{    $conf{OUTPUT_FIELDS} = [qw(}, "\n",
			 $conf{OUTPUT_FIELDS}, qq{)];\n};
#        } elsif (/^EXT_SUB2?$/) {
#            print $fh qq{    \$conf{$_} = sub \{}, "\n",
#             $conf{$_}, qq{\n\    \};\n};
		} else {
			print $fh qq{    chomp(\$conf{$_} = <<'_STR_${_}_');\n$conf{$_}\n_STR_${_}_\n};
		}
	}
	print $fh qq{\n    \%conf;\n\n\}\n\n1;\n};
	close($fh);

	($conf{conffile}, $conf{conf_id});

}

sub mk_errmsg_admin {

	my @errmsg = @_;

	my $errmsg = join("\n", map { qq|<li>$_</li>| } map { h($_) } @errmsg);
	if ($errmsg ne "") {
		return qq|<ul id="errmsg">\n$errmsg\n</ul>|;
	}
	return;

}

sub get_output_form_admin {

	use HTML::SimpleParse;

	my($content, %d) = @_;   ### 差し込みデータ

	for my $k(keys %d) {
		next if $d{$k} =~ /^<option /i;
		for my $v_(split(/\!\!\!|\|\|\|/, $d{$k})) {
			$d{ join("\0", $k, $v_) } = $v_;
		}
	}
	my $p = new HTML::SimpleParse($content);
	my %is_formtag = map { $_ => 1 } qw(input select textarea);
	my $output;   ### 出力用htmlデータ
	my $select_flag = 0; # select/textareaの閉じ対応チェック用
	my $textarea_flag = 0;
	my $now_name; # optionタグのname保持用
	my $option_stack; # optionタグのvalue用コンテナ

	for ($p->tree) {
		my %c = %$_;
		@c{qw(tagname content_)} = split(/\s+/, $c{"content"}, 2);
		$c{"tagname"} = lc($c{"tagname"});
		if ($c{"type"} eq "starttag") {
			my %h = $p->parse_args( $c{"content_"} );
			{ my %h_; for (keys %h) { $h_{lc($_)} = $h{$_} }; %h = %h_ }
			if ($c{"tagname"} eq "input") {
				$h{"type"} = lc($h{"type"});
				if ($h{"type"} eq "" or $h{"type"} eq "text" or $h{"type"} eq "hidden" or $h{"type"} eq "password" or $h{"type"} eq "tel" or $h{"type"} eq "email") {
					$h{"value"} = $d{$h{"name"}};
				} elsif ($h{"type"} eq "checkbox" or $h{"type"} eq "radio") {
					if (exists $d{ join("\0", $h{"name"}, $h{"value"}) }) {
						$h{"checked"} = "checked";
					} else {
						delete $h{"checked"} if exists $h{"checked"};
					}
				}
				$output .= get_output_form_admin_remake_tag($c{"tagname"}, %h);
			} elsif ($c{"tagname"} eq "select") {
				$select_flag = 1;
				$now_name = $h{"name"};
				$output .= "<$c{content}>";
			} elsif ($c{"tagname"} eq "textarea") {
				$textarea_flag = 1;
				$now_name = $h{"name"};
				$output .= qq|<$c{"content"}>|;
			} elsif ($c{"tagname"} eq "option") {
				if (exists $h{"value"}) {
					$output .= get_output_form_admin_set_option_tag($now_name, \%h, \%d);
				} else {
					$option_stack = {%h};
				}
			} else {
				$output .= qq|<$c{"content"}>|; # returns as-is
			}

		} elsif ($c{"type"} eq "text") {
			if ($select_flag) {
				if ($option_stack) {
					my ($content, $space) = $c{"content"} =~ /^(.*)(\s*)$/;
					$option_stack->{"value"} = $content;
					$output .= get_output_form_admin_set_option_tag($now_name, $option_stack, \%d);
					$output .= $space;
				} else {
					$output .= $c{"content"};
				}
			} elsif ($textarea_flag) {
				1;  # skip -- endtagで処理
			} else {
				$output .= $c{"content"};
			}
		} elsif ($c{"type"} eq "endtag") {
			if ($c{tagname} eq "/textarea") {
			    $output .= $d{$now_name};
			    $textarea_flag = 0;
			} elsif ($c{tagname} eq "/option" or $c{"tagname"} eq "/select") {
				if ($option_stack) {
					my ($content, $space) = $c{"content"} =~ /^(.*)(\s*)$/;
					$option_stack->{"value"} = $content;
					$output .= get_output_form_admin_set_option_tag($now_name, $option_stack, \%d);
					$output .= $space;
				}
				$option_stack = 0;
				$select_flag = 0;
			}
			$output .= qq|<$c{tagname}>|;
		} else {
			$output .= "<$c{content}>";
		}
	}

    return $output;

}

sub get_output_form_admin_remake_tag {

	my($tagname, %h) = @_;

	return "<$tagname "
	 . join(" ", (map { qq|$_="|.scalar($h{$_}=~s/"/&quot;/g,$h{$_}).qq|"| }
	  sort grep { $_ ne "/" } keys %h), $tagname =~ /(?:input|img|link)$/ ? "/" : ())
	 . ">";

}

sub get_output_form_admin_set_option_tag {

	my($now_name, $h, $d) = @_;
	my %h = %$h;
	my %d = %$d;

	if (exists $d{qq|$now_name\0$h{"value"}|}) {
		$h{"selected"} = "selected";
	} else {
		delete $h{"selected"} if exists $h{"selected"};
	}
	return get_output_form_remake_tag("option", %h);

}

sub mk_sysconffile {

	my %conf = @_;

	my $date = get_datetime(time);
	open(my $fh, ">", "./f_mailer_sysconf.pl")
	 or error(get_errmsg("620", $!));
	print $fh <<STR;
#
# $CONF{prod_name} v$CONF{version} 設定ファイル
# $CONF{copyright2} Perl Script Laboratory All rights reserved.
#
# f_mailer_sysconf.pl
#
# このファイルはプログラムによって自動生成されました。
# 生成日時: $date

#use utf8;
package conf;

 sub sysconf {

	my %conf;

STR

	my $condstr;

	foreach (qw(LANG_DEFAULT SENDMAIL_FLAG SENDMAIL SMTP_HOST ALLOW_FROM)) {
		print $fh qq{    chomp(\$conf{$_} = <<_STR_${_}_);\n$conf{$_}\n_STR_${_}_\n};
	}
	print $fh qq{\n    \%conf;\n\n\}\n\n1;\n};
	close($fh);

}

sub passwd_compare {

	my $plain_passwd = shift;
	my $crypt_passwd = shift;
	return crypt($plain_passwd, $crypt_passwd) eq $crypt_passwd ? 1 : 0;

}

sub passwd_read {

	my ($login_id) = shift;

	open(my $fh, "<", "./data/passwd.cgi")
	 or error(get_errmsg("630", $!));
	while (<$fh>) {
		chomp;
		my ($id, $passwd_encrypted) = split(/:/, $_, 2);
		if ($id eq $login_id) {
			close($fh);
			return $passwd_encrypted;
		}
	}
	return;
}

sub passwd_write {

	my $passwd = shift || 12345;
	open(my $fh, ">", "./data/passwd.cgi")
	 or error(get_errmsg("640", $!));
	my $salt = join("", map { (0..9,"a".."z","A".."Z")[rand(62)] } (1..8));
	print $fh "admin:", crypt($passwd, index(crypt('a','$1$a$'),'$1$a$') == 0 ? "\$1\$$salt\$" : $salt);
	close($fh);

}

sub printhtml_admin {

	my($files, %tr) = @_;
	my $htmlstr;
	my $submit_type;
	my %data;
	my $fh;
#d($tr{"errmsg"});
	if (-e "tmpl/_header.html") {
		open($fh, "<", "tmpl/_header.html") or die $!;
		$htmlstr = join("", <$fh>);
		close($fh);
	}
	for my $file(split(/\s+/, $files)) {
		open($fh, "tmpl/$file")
		 or die("printhtml_admin: $fileが開けませんでした。: $!");
		$htmlstr .= join("", <$fh>);
		close($fh);
	}
	if (-e "tmpl/_footer.html") {
		open($fh, "<", "tmpl/_footer.html") or die $!;
		$htmlstr .= join("", <$fh>);
		close($fh);
	}

	if (exists $tr{"errmsg"} and ref $tr{"errmsg"} eq "ARRAY") {
		$htmlstr =~ s/<!-- *(?:##)?errmsg(?:##)? *-->/mk_errmsg_admin(@{$tr{"errmsg"}})/e;
		delete $tr{"errmsg"};
	} else {
		$htmlstr =~ s/<!-- *(?:##)?errmsg(?:##)? *-->//;
	}

	for (keys %tr) {
		next if ref $tr{$_};
		$htmlstr =~ s/##$_##/$tr{$_}/g;
	}

	for (keys %CONF) {
		next if ref $CONF{$_};
		$htmlstr =~ s/##$_##/$CONF{$_}/g;
	}

	$htmlstr =~ s/##COPYRIGHT##/$ENV{"SCRIPT_FILENAME"} =~ m#admin# ? $CONF{"copyright_html_footer_admin"} : $CONF{"copyright_html_footer"}/eg;
#	$htmlstr =~ s/##prod_name##/$CONF{"prod_name"}/g;
#	$htmlstr =~ s/##version##/$CONF{"version"}/g;

	$htmlstr = get_output_form_admin($htmlstr, %FORM, %tr);
	print "Content-type: text/html; charset=utf-8\n\n$htmlstr";

}

1;
