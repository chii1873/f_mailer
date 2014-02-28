# ---------------------------------------------------------------
#  - システム名    フォームデコード+メール送信 (FORM MAILER)
#  - バージョン    0.62
#  - 公開年月日    2007/10/9
#  - スクリプト名  f_mailer_lib_admin.pl
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
use utf8;
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

	open(my $fh, "<:utf8", "./data/conffields.txt")
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
		open(my $fh, "<:utf8", "./data/$_") or error(get_errmsg("603", $_, $!));
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
		open(my $fh, ">:utf8", "./data/confext/ext_$conf{conffile}")
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

use utf8;
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

	open(my $fh, ">:utf8", "data/conf/$conf{conffile}")
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

use utf8;
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

sub mk_sysconffile {

	my %conf = @_;

	my $date = get_datetime(time);
	open(my $fh, ">:utf8", "./f_mailer_sysconf.pl")
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

use utf8;
package conf;

 sub sysconf {

	my %conf;

STR

	my $condstr;

	foreach (qw(LANG_DEFAULT SENDMAIL_FLAG SENDMAIL SMTP_HOST ALLOW_FROM ERRMSG_STYLE_UL ERRMSG_STYLE_LI)) {
		print $fh qq{    chomp(\$conf{$_} = <<_STR_${_}_);\n$conf{$_}\n_STR_${_}_\n};
	}
	print $fh qq{\n    \%conf;\n\n\}\n\n1;\n};
	close($fh);

}

sub passwd_compare {

	my $plain_passwd = shift;
	my $crypt_passwd = passwd_read();
	return crypt($plain_passwd, $crypt_passwd) eq $crypt_passwd ? 1 : 0;

}

sub passwd_read {

	open(my $fh, "<:utf8", "./data/passwd.cgi")
	 or error(get_errmsg("630", $!));
	my $passwd = <R>;
	close(R);
	return $passwd;

}

sub passwd_write {

	my $passwd = shift || 12345;
	open(my $fh, ">:utf8", "./data/passwd.cgi")
	 or error(get_errmsg("640", $!));
	my $salt = join("", map { (0..9,"a".."z","A".."Z")[rand(62)] } (1..8));
	print $fh crypt($passwd, index(crypt('a','$1$a$'),'$1$a$') == 0 ? "\$1\$$salt\$" : $salt);
	close($fh);

}

1;
