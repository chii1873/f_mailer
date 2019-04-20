
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p113 {

	my ($p, @errmsg) = @_;

	### セッションデータ取り出し
	my $d = $CONF{"session"}->param("p111_data");

	### CONFID払い出し
	my ($confid, $file) = gen_confid();
	my %newconf = (
		"id" => $confid,
		"file" => $file,
		"label" => $d->{"label"},
		"lang" => $d->{"LANG"},
		"date" => get_datetime(),
	);
	$d->{"confid"} = $confid;

	### 設定ファイル書き出し
	conf_write($confid, $file, %$d);

	### 拡張設定ファイル生成
	open(my $fh, "<", "data/confext/ext_default.pl") or error(get_errmsg("004", $!, "default"));
	my $confext = join("", <$fh>);
	close($fh);
	$confext =~ s/##prod_name##/$CONF{"prod_name"}/g;
	$confext =~ s/##version##/$CONF{"version"}/g;
	$confext =~ s/##copyright2##/$CONF{"copyright2"}/g;
	$confext =~ s/##file##/$newconf{"file"}/g;
	$confext =~ s/##date##/$newconf{"date"}/g;
	open($fh, ">", qq|data/confext/ext_$newconf{"file"}.pl|) or error(get_errmsg("005", $!));
	print $fh $confext;
	close($fh);

	### シリアルNoファイル生成
	open($fh, ">", "data/serial/$confid") or error(get_errmsg("451", $!));
	close($fh);

	### 送信データファイルディレクトリ生成
	mkdir("data/output/$confid") or error(get_errmsg("452", $!));

	### 設定一覧データ追加
	my $conflist = conflist_read();
	push(@$conflist, \%newconf);
	conflist_write($conflist);

	### セッションデータ削除
	$CONF{"session"}->param("p111_data", "");

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"confid" => $d->{"confid"},
	);
	exit;

}

1;
