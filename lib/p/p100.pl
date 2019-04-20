
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p100 {

	my ($p, @errmsg) = @_;

	my %lang = map { $_->[0] => $_->[1] } get_langlist();
	my $list;
	for my $d(get_conflist()) {
		open(my $fh, "<", qq|data/serial/$d->{"id"}|);
		my $serial = <$fh> || "-";
		close($fh);
		$list .= <<STR;
<tr>
	<td>$d->{"id"}</td>
	<td>$d->{"label"}</td>
	<td>($d->{"lang"})$lang{$d->{"lang"}}</td>
	<td class="r"><span class="serial_number">$serial</span><button class="btn_s btn_submit" id="btn_submit_to_124" data-confid="$d->{"id"}">変更</button></td>
	<td>
		<!-- button class="btn_s btn_submit" id="btn_submit_to_101" data-confid="$d->{"id"}">確認</button --><button class="btn_s btn_submit" id="btn_submit_to_121" data-confid="$d->{"id"}">修正</button><button class="btn_s btn_submit" id="btn_submit_to_132" data-confid="$d->{"id"}" data-confirm="1" data-confirm_message="この設定を削除します。一度削除すると元には戻せません。よろしいですか？">削除</button> |
		<button class="btn_s btn_submit" id="btn_submit_to_140" data-confid="$d->{"id"}">送信データ</button><button class="btn_s btn_submit" id="btn_submit_to_150" data-confid="$d->{"id"}" data-token_ignore="1">エクスポート</button>
	</td>
</tr>
STR
	}

	$list ||= qq|<tr><td colspan="5" class="c">(登録がありません)</td></tr>|;

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"list" => $list,
	);
	exit;

}

1;
