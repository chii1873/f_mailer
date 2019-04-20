
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p132 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
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
	if (-d qq|data/output/$FORM{"confid"}|) {
		opendir(my $dir, qq|data/output/$FORM{"confid"}|);
		for (grep(!/^\.\.?$/, readdir($dir))) {
			unlink(qq|data/output/$FORM{"confid"}/$_|);
		}
		rmdir(qq|data/output/$FORM{"confid"}|) or error(get_errmsg("453", $FORM{"confid"}));
	}

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"confid" => $FORM{"confid"},
	);
	exit;

}

1;
