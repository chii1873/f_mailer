use strict;
use vars qw($q %FORM %CONF $name_list_ref %alt %ERRMSG);

sub login_form {

	output_form("LOGIN", \@_);

}

sub login_init {

	### 2021-01-13 PATH_INFOからCONFIDを取得
	### PATH_INFOが指定されているときは、/[CONFID]/[KEY]または/[CONFID]のいずれかのみOK
	### CONFIDが取得できたら設定ファイルをロードする
	if ($ENV{"PATH_INFO"}) {
		if ($ENV{"PATH_INFO"} =~ m#/(\d{6})/([0-9a-zA-Z\-_]+)$#) {
			$FORM{"CONFID"} = $1;
			$FORM{"KEY"} = $2;
			my $filename = get_conffile_by_id($FORM{"CONFID"})
			 or error(get_errmsg("006"));
	
		} elsif ($ENV{"PATH_INFO"} =~ m#/(\d{6})$#) {
			$FORM{"CONFID"} = $1;
			$FORM{"KEY"} = "";
		} else {
			error(get_errmsg("007")."(".__LINE__.")");
		}
	}

}

sub login_proc {

	### キーによるログインモード
	login_proc_key() if $CONF{"USE_LOGIN"} == 2;

	### ID・パスワードによるログイン
	login_proc_id() if $CONF{"USE_LOGIN"} == 1;

}

sub login_proc_id {

	# CONFIDが指定されているとき
	if ($ENV{"PATH_INFO"}) {
		if ($FORM{"CONFID"}) {
			### セッション初期化
			$CONF{"session"}->clear();
			### ログイン画面を表示する
			$CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|, {
				"LOGIN" => 1,
				"CONFID" => $FORM{"CONFID"},
			});
			login_form();
		} else {
			### 不正なアクセスエラー
			error(get_errmsg("007")."(".__LINE__.")");
		}

	# ログイン処理
	} elsif ($FORM{"LOGIN"} == 1) {
		my %d = (%{ $CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|) }, %FORM);
		$CONF{"session"}->param(qq|formdata-$FORM{"CONFID"}|, { %d });

		if ($FORM{"ID"} eq "") {
			### ID未入力
			login_form(get_errmsg("549"));
		} elsif ($FORM{"PW"} eq "") {
			### PW未入力
			login_form(get_errmsg("550"));
		} else {
			my $logged_in = 0;
			my %d = get_data_from_keyfile($FORM{"CONFID"}, "ID"=>$FORM{"ID"});
#BEGIN{ print "Content-type: text/html; charset=utf-8\n\n"; $| =1; open(STDERR, ">&STDOUT"); }
#d(\%d);
			if ($d{"ID"} eq $FORM{"ID"} and $d{"PW"} eq $FORM{"PW"}) {

				if ($CONF{"SEND_ONCE"}) {
					if (-e qq|data/key/$FORM{"CONFID"}/done/ID_$FORM{"ID"}|) {
						### すでに送信済エラー

					} else {
						$logged_in = 1;
					}
				} else {
					$logged_in = 1;
				}
			} else {
				login_form(get_errmsg("551"));
			}
			if ($logged_in) {
				### ログイン
				$CONF{"session"}->param(qq|LOGGED_IN_$FORM{"CONFID"}|, 1);
				$CONF{"session"}->param(qq|LOGIN_$FORM{"CONFID"}|, { %d });
				%FORM = (%FORM, %d);
				### フォーム表示
				$FORM{"FORM"} = 1;
			}
		}

	# ログイン状態のとき(セッションデータ)
	} elsif ($CONF{"session"}->param(qq|LOGGED_IN_$FORM{"CONFID"}|)) {
		my $d = $CONF{"session"}->param(qq|LOGIN_$FORM{"CONFID"}|);
		if ($FORM{"ID"} ne "" and $d->{"ID"} ne $FORM{"ID"}) {
			### 不正なアクセスエラー
			error(get_errmsg("007")."(".__LINE__.")");
		}
		%FORM = (%FORM, %{ $d });

	# 不正なアクセスエラー
	} else {
		### 不正なアクセスエラー
		error(get_errmsg("007")."(".__LINE__.")");
	}

}

sub login_proc_key {

	# CONFIDとKEYが指定されているとき
	if ($ENV{"PATH_INFO"}) {
		if ($FORM{"CONFID"} && $FORM{"KEY"}) {
			### セッション初期化
			$CONF{"session"}->clear();
			my %d = get_data_from_keyfile($FORM{"CONFID"}, "KEY"=>$FORM{"KEY"});
			my $logged_in = 0;
			if (keys %d == 0) {
				### 不正なアクセスエラー
				error(get_errmsg("007")."(".__LINE__.")");

			} elsif ($CONF{"SEND_ONCE"}) {
				if (-e qq|data/key/$FORM{"CONFID"}/done/KEY_$FORM{"KEY"}|) {
					### すでに送信済エラー
					error(get_errmsg("012"));

				} else {
					$logged_in = 1;
				}
			} else {
				$logged_in = 1;
			}
			if ($logged_in) {
				### ログイン処理、初期値データをセット
				$CONF{"session"}->param(qq|LOGGED_IN_$FORM{"CONFID"}|, 1);
				$CONF{"session"}->param(qq|LOGIN_$FORM{"CONFID"}|, { %d });
				%FORM = (%FORM, %d);
				### フォーム表示
				$FORM{"FORM"} = 1;
			}

		} else {
			### 不正なアクセスエラー
			error(get_errmsg("007")."(".__LINE__.")");
		}

	# ログイン状態のとき(セッションデータ)
	} elsif ($CONF{"session"}->param(qq|LOGGED_IN_$FORM{"CONFID"}|)) {
		my $d = $CONF{"session"}->param(qq|LOGIN_$FORM{"CONFID"}|);
		if ($FORM{"KEY"} ne "" and $d->{"KEY"} ne $FORM{"KEY"}) {
			### 不正なアクセスエラー
			error(get_errmsg("007")."(".__LINE__.")");
		}
		%FORM = (%FORM, %{ $d });

	# 不正なアクセスエラー
	} else {
		### 不正なアクセスエラー
		error(get_errmsg("007")."(".__LINE__.")".Dumper(\%FORM).Dumper($CONF{"session"}));
	}

}

1;
