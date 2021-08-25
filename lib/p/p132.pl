
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p132 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
error(Dumper(\%FORM));
		error(get_errmsg("470"));
	}

	my $file = get_conffile_by_id($FORM{"confid"});
	($file) = $file =~ /^([\w\.\-\_]+)$/;

	### 設定一覧データから削除
	my $conflist = conflist_read();
	my @conflist;
	for my $json(@$conflist) {
		next if $json->{"id"} eq $FORM{"confid"};
		push(@conflist, $json);
	}
	conflist_write(\@conflist);

	### 設定ファイル削除
	unlink("./data/conf/$file.json") or error(get_errmsg("473", "$file.json"));

	### 拡張設定ファイル削除
	if (-e "./data/confext/ext_$file.pl") {
		unlink("./data/confext/ext_$file.pl") or error(get_errmsg("474", "$file.pl"));
	}

	### シリアルNoファイル削除
	if (-e qq|./data/serial/$FORM{"confid"}|) {
		unlink(qq|./data/serial/$FORM{"confid"}|) or error(get_errmsg("475", $FORM{"confid"}));
	}

	### 送信データファイルディレクトリ削除
	### 当面、削除はせずにフォルダ名のリネームにする
	if (-d qq|data/output/$FORM{"confid"}|) {
#		opendir(my $dir, qq|data/output/$FORM{"confid"}|);
#		for (grep(!/^\.\.?$/, readdir($dir))) {
#			unlink(qq|data/output/$FORM{"confid"}/$_|);
#		}
#		rmdir(qq|data/output/$FORM{"confid"}|) or error(get_errmsg("453", $FORM{"confid"}));
		(my $dt = get_datetime()) =~ s/\D//g;
		rename(qq|data/output/$FORM{"confid"}|, qq|data/output/__$FORM{"confid"}_deleted_$dt|);
		if (! -d qq|data/output/__$FORM{"confid"}_deleted_$dt|) {
			error(get_errmsg("453", $FORM{"confid"}));
		}
	}

	### 回答済みフラグファイル用ディレクトリ削除
	if (-d qq|data/key/$FORM{"confid"}/done|) {
		opendir(my $dir, qq|data/key/$FORM{"confid"}/done|);
		for (grep(!/^\.\.?$/, readdir($dir))) {
			unlink(qq|data/key/$FORM{"confid"}/done/$_|);
		}
		rmdir(qq|data/key/$FORM{"confid"}/done|) or error(get_errmsg("457", $FORM{"confid"}));
	}

	### ログイン・初期値データディレクトリ削除
	if (-d qq|data/key/$FORM{"confid"}|) {
		opendir(my $dir, qq|data/key/$FORM{"confid"}|);
		for (grep(!/^\.\.?$/, readdir($dir))) {
			unlink(qq|data/key/$FORM{"confid"}/$_|);
		}
		rmdir(qq|data/key/$FORM{"confid"}|) or error(get_errmsg("455", $FORM{"confid"}));
	}

	### 添付ファイル用ディレクトリ削除
	### 当面、削除はせずにフォルダ名のリネームにする
	if (-d qq|data/att/$FORM{"confid"}|) {
		(my $dt = get_datetime()) =~ s/\D//g;
		rename(qq|data/att/$FORM{"confid"}|, qq|data/att/__$FORM{"confid"}_deleted_$dt|);
		if (! -d qq|data/att/__$FORM{"confid"}_deleted_$dt|) {
			error(get_errmsg("458", $FORM{"confid"}, $dt));
		}
	}

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"confid" => $FORM{"confid"},
	);
	exit;

}

1;
