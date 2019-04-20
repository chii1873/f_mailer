
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p103 {

	my ($p, @errmsg) = @_;

	### 新規作成…デフォルト値を読み込む
	if ($FORM{"mode"} eq "blank") {
		open(my $fh, "<", "data/conf/default.json") or error(get_errmsg("476", $!));
		my $json = json_decode(<$fh>);
		$CONF{"session"}->param("p111_data", $json);

	### 既存の設定をコピー
	} elsif ($FORM{"mode"} eq "copy") {
		if (! $FORM{"confid0"}) {
			p("102", get_errmsg("477"));
		}
		my %conf = conf_read($FORM{"confid0"});
		$CONF{"session"}->param("p111_data", \%conf);

	### 既存の設定をコピー
	} elsif ($FORM{"mode"} eq "import") {
		if (! $FORM{"import_file"}) {
			p("102", get_errmsg("477"));
		}
		my $json = get_file_stream($q, "import_file");

		eval { from_json($json); };
		if ($@) {
			p("102", get_errmsg("478", $@));
		}
		my %conf = conf_read("", $json, "102");
		$CONF{"session"}->param("p111_data", \%conf);

	} else {
		p("102", "不正なアクセスです。");
	}


	p("111");
	exit;

}

1;
