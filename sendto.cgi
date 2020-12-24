#!/usr/bin/perl
BEGIN {
#	$| = 1;
#	print "Content-type: text/html\n\n";
#	open(STDERR, ">&STDOUT");
}

use strict;
use lib qw(./lib);
use vars qw($q %FORM %CONF %alt $name_list_ref);
use CGI;
use Unicode::Japanese;
use POSIX qw(SEEK_SET);
use CGI::Carp qw(fatalsToBrowser);
use HTML::SimpleParse;
use LWP::Simple;
use Fcntl ':flock';
use Data::Dumper;
sub d { die Dumper @_ }
$ENV{PATH} = "/usr/bin:/usr/sbin:/usr/local/bin:/bin";
require './f_mailer_lib.pl';
require './f_mailer_lib_admin.pl';
require './f_mailer_sysconf.pl';
%CONF = (setver(), conf::sysconf());
$q = new CGI;
($name_list_ref, %FORM) = decoding($q);

$CONF{"sendto_formlist"} = {

	1 => {
		label  => "お問い合わせフォーム(/contact/index.html)",
		path   => "index.html",
		name   => "kind",
		CONFID => 549456,
	},

};

login() if $FORM{"action"} eq "login";
login_form() unless get_cookie("FORM_MAILER_ADMIN");
confirm() if $FORM{"action"} eq "confirm";
done() if $FORM{"action"} eq "done";
form() if $FORM{"action"} eq "form";
logout() if $FORM{"action"} eq "logout";
form_select();

sub confirm {

	my %form = temp_read_sendto($FORM{"temp"});
	temp_write_sendto($FORM{"temp"}, %form, %FORM);

	if ($form{"formlist"} eq "") {
		error("設定対象フォームが選択されていません。");
	} elsif (! $CONF{"sendto_formlist"}{$form{"formlist"}}) {
		error("該当する設定対象フォームがありません。");
	}

	my $conffile;
	foreach my $conf(get_conflist()) {
		my($conf_id, $filename, $label) = map { $conf->{$_} } qw(id file label);
		if ($conf_id eq $CONF{"sendto_formlist"}{$form{"formlist"}}{"CONFID"}) {
			$conffile = $filename;
			last;
		}
	}
	$conffile or error("指定されたFORM MAILER設定ファイルの登録がありませんでした。");
	eval qq|require "./data/conf/$conffile";|;
	error("FORM MAILER設定ファイルの読み込みができませんでした。: $@") if $@;
	my %f_mailer_conf = conf::conf();
	my $path = $f_mailer_conf{FORM_TMPL} || $CONF{"sendto_formlist"}{$form{"formlist"}}{"path"};


	my @values = split(/,/, $form{"values"});
	my $list;
	for my $value(@values) {
		$FORM{"sendto_$value"} =~ s|\n|<br />\n|g;
		$list .= <<STR;
<tr><td>$value</td><td>$FORM{"sendto_$value"}&nbsp;</td></tr>
STR
    }


	printhtml("tmpl/sendto_confirm.html",
	 "temp" => $FORM{"temp"},
	 "STYLESHEET" => $CONF{"STYLESHEET"},
	 "CONFID" => $CONF{"sendto_formlist"}{$form{"formlist"}}{"CONFID"},
	 "SENDTO" => join("<br />", split(/\s*,\s*|\r?\n/, $f_mailer_conf{"SENDTO"})),
	 "path" => $path, "element_name"=>$CONF{"sendto_formlist"}{$form{"formlist"}}{"name"},
	 "label" => $CONF{"sendto_formlist"}{$form{"formlist"}}{"label"},
	 "list" => $list,
	);
	exit;

}

sub done {

	my %form = temp_read_sendto($FORM{"temp"});
	if ($form{"formlist"} eq "") {
		error("設定対象フォームが選択されていません。");
	} elsif (! $CONF{"sendto_formlist"}{$form{"formlist"}}) {
		error("該当する設定対象フォームがありません。");
	}

	open(my $fh, ">", qq|data/sendto/$CONF{"sendto_formlist"}{$form{"formlist"}}{"CONFID"}|)
	 or error(qq|設定データ(data/sendto/$CONF{"sendto_formlist"}{$form{"formlist"}}{"CONFID"})の書き出しができませんでした。: $!|);
	print $fh $CONF{"sendto_formlist"}{$form{"formlist"}}{"name"}, "\n";

	for my $value(split(/,/, $form{"values"})) {
		$form{"sendto_$value"} =~ s|\s+|,|g;
		print $fh qq|$value:$form{"sendto_$value"}\n|;
	}
	close($fh);

	printhtml("tmpl/sendto_done.html",
	 "STYLESHEET" => $CONF{"STYLESHEET"},
	);
	exit;

}

sub error {

	printhtml("tmpl/sendto_error.html",
	 "STYLESHEET" => $CONF{"STYLESHEET"},
	 errmsg => join("", map { "<li>$_\n</li>" } map { html_output_escape($_) } @_),
#     (map { $_=>$CONF{$_} } keys %CONF), (map { $_=>$FORM{$_} } keys %FORM),
	);
	exit;

}

sub form {

	if ($FORM{"formlist"} eq "") {
		error("設定対象フォームを選択してください。");
	} elsif (! $CONF{"sendto_formlist"}{$FORM{"formlist"}}) {
		error("該当する設定対象フォームがありません。");
	}

	my $conffile;
	foreach my $conf(get_conflist()) {
		my($conf_id, $filename, $label) = map { $conf->{$_} } qw(id file label);
		if ($conf_id eq $CONF{"sendto_formlist"}{$FORM{"formlist"}}{"CONFID"}) {
			$conffile = $filename;
			last;
		}
	}
	$conffile or error("指定されたFORM MAILER設定ファイルの登録がありませんでした。");
	eval qq|require "./data/conf/$conffile";|;
	error("FORM MAILER設定ファイルの読み込みができませんでした。: $@") if $@;
	my %f_mailer_conf = conf::conf();
	my $path = $f_mailer_conf{"FORM_TMPL"} || $CONF{"sendto_formlist"}{$FORM{"formlist"}}{"path"};

	my $content;
	if ($path =~ m|^https?://|) {
		$content = get($path)
		 or error("指定されたURL($path)からHTMLソースを取得できませんでした。: $!");
	} elsif ($path ne "") {
		open(my $fh, "<", $path)
		 or error("指定されたURL($path)からHTMLソースを取得できませんでした。: $!");
		$content = join("", <$fh>);
		close($fh);
	} else {
		error('URLが指定されていません。');
	}

	my $p = new HTML::SimpleParse($content);

	my $selectflag = "";
	my @values;
	my %values_exist;
#use Data::Dumper;
#die Dumper([$p->tree]);
my $debug = qq|\$FORM{"formlist"}=$FORM{"formlist"}, \$CONF{"sendto_formlist"}{$FORM{"formlist"}}{name} = $CONF{"sendto_formlist"}{$FORM{"formlist"}}{name}, \n|;
	foreach ($p->tree) {
		my %c = %$_;
		@c{qw(tagname content)} = split(/\s+/, $c{"content"}, 2);
		next if $c{"type"} eq "text";
		my %h = $p->parse_args( $c{"content"} );
	
$debug .= qq|\$c{type}=$c{type}, \$c{"tagname"}=$c{"tagname"}, \$h{"TYPE"}=$h{"TYPE"}, \$h{"NAME"}=$h{"NAME"}, \$h{"VALUE"}=$h{"VALUE"}, \$selectflag=$selectflag\n|;
		if ($c{type} eq "starttag" and $c{"tagname"} =~ /^input$/i
		 and $h{"TYPE"} =~ /^(?:radio|checkbox)$/i
		 and $h{"NAME"} eq $CONF{"sendto_formlist"}{$FORM{"formlist"}}{"name"}
		 and $h{"VALUE"} ne "") {

			push(@values, $h{"VALUE"}) unless $values_exist{$h{"VALUE"}}++;

        	} elsif ($c{"tagname"} =~ m|^/?select$|i) {

        		if ($c{type} eq "starttag") {
        			$selectflag = $h{"NAME"};
        		} elsif ($c{type} ne "starttag") {
        			$selectflag = undef;
        		}

		} elsif ($c{type} eq "starttag" and $c{"tagname"} =~ /^option$/i
		 and $selectflag eq $CONF{"sendto_formlist"}{$FORM{"formlist"}}{"name"}
		 and $h{"VALUE"} ne "") {

			push(@values, $h{"VALUE"}) unless $values_exist{$h{"VALUE"}}++;

		}
	}

#die($debug);
### FORM_TMPLとFORM_TMPL_CHARSETの値を使う
### checkboxは後日対応
### とりあえずsjisに変換してから処理

	my %sendto_list;
	open(my $fh, "<", qq|data/sendto/$CONF{"sendto_formlist"}{$FORM{"formlist"}}{"CONFID"}|)
#	 or error("設定データがありませんでした。: $!");
	;
	my %sendto;
	my $list;
	<$fh>;  # 1行目は判定するname属性名
	while (my $line = <$fh>) {
		chomp $line;
		my($value, $sendto) = split(/:/, $line);
		$sendto_list{$value} = join("\n", split(/,/, $sendto));
	}
	close($fh);

	for my $value(@values) {
		if ($f_mailer_conf{"FORM_TMPL_CHARSET"} =~ /^(?:sjis|euc)$/) {
			$value = Unicode::Japanese->new($value, $f_mailer_conf{FORM_TMPL_CHARSET})->get;
		}
		$list .= <<STR;
<tr>
	<td>$value</td>
	<td><textarea name="sendto_$value" cols="30" rows="2">$sendto_list{$value}</textarea></td>
</tr>
STR
	}

	my $temp = temp_write_sendto(undef,
	 "values" => join(",", @values),
	 "formlist"=> $FORM{"formlist"},
	 "path" => $path,
	);

	printhtml("tmpl/sendto_form.html",
	 temp=>$temp,
	 "STYLESHEET" => $CONF{"STYLESHEET"},
	 "CONFID" => $CONF{"sendto_formlist"}{$FORM{"formlist"}}{"CONFID"},
	 "SENDTO" => join("<br />", split(/\s*,\s*|\r?\n/, $f_mailer_conf{"SENDTO"})),
	 "path" => $path, element_name=>$CONF{"sendto_formlist"}{$FORM{"formlist"}}{name},
	 "label" => $CONF{"sendto_formlist"}{$FORM{"formlist"}}{label},
	 "list" => $list,
	 "values" => join(",", @values),
	);
	exit;

}

sub form_select {

	my $list;
	for (sort { $a <=> $b } keys %{$CONF{"sendto_formlist"}}) {
		$list .= qq|<option value="$_">$CONF{"sendto_formlist"}{$_}{"label"}</option>\n|;
	}

	printhtml("tmpl/sendto_form_select.html",
	 "STYLESHEET" => $CONF{"STYLESHEET"},
	 "list" => $list,
	);
	exit;

}


sub login {

	$FORM{"passwd"} or error("パスワードを入力してください。");
	passwd_write() unless -e "data/passwd.cgi";
	passwd_compare($FORM{"passwd"}) or error("パスワードが違います。");

	set_cookie("FORM_MAILER_ADMIN", "", "login");
	set_cookie("FORM_MAILER_ADMIN_CACHE", 30 * 86400,
	 ($FORM{"do_cache"} ? $FORM{"passwd"} : ""));
	print "Location: sendto.cgi\n\n";
	exit;

}

sub login_form {

	my $passwd = get_cookie("FORM_MAILER_ADMIN_CACHE");
	printhtml("tmpl/sendto_login_form.html",
	 "passwd" => $passwd,
	 "STYLESHEET" => $CONF{"STYLESHEET"},
	 "do_cache"=>$passwd ? "checked" : "",
	);
	exit;
	
}

sub logout {

	set_cookie("FORM_MAILER_ADMIN");
	printhtml("tmpl/sendto_logout.html",
	 "STYLESHEET" => $CONF{"STYLESHEET"},
	);
	exit;

}

sub temp_read_sendto {

	my($temp) = @_;
	my $path = "temp";
	my %form;
	open(my $fh, "<", "$path/$temp") or error("不正なアクセスです。: $temp");
	while (<$fh>) {
	    chomp;
	    my($k, $v) = split(/:/, $_, 2);
	    $v =~ s/\x0b/\n/g;
	    $form{$k} = $v;
	}
	close($fh);
	return %form;

}

sub temp_write_sendto {

	my($temp, %form) = @_;
	my $path = "temp";
	$temp ||= time . $$;
	open(my $fh, ">", "$path/$temp")
	 or error("一時ファイルに書き込みできませんでした。: $!");
	foreach (keys %form) {
	    (my $value = $form{$_}) =~ s/\r?\n/\x0b/g;
	    print $fh "$_:$value\n";
	}
	close($fh);
	return $temp;

}
