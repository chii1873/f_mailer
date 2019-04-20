
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p123 {

	my ($p, @errmsg) = @_;

	### セッションデータ取り出し
	my $d = $CONF{"session"}->param("p111_data");

	### 設定ファイル書き出し
	conf_write($d->{"confid"}, get_conffile_by_id($d->{"confid"}), %$d);

	### 設定一覧データ更新
	my $conflist = conflist_read();
	my @conflist;
	for my $json(@$conflist) {
		if ($json->{"id"} eq $d->{"confid"}) {
			$json->{"label"} = $d->{"label"};
			$json->{"lang"} = $d->{"LANG"};
			$json->{"date"} = get_datetime();
		}
		push(@conflist, $json);
	}
	conflist_write(\@conflist);

	### セッションデータ削除
	$CONF{"session"}->param("p111_data", "");

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"confid" => $d->{"confid"},
	);
	exit;

}

1;
