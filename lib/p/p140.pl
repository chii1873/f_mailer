
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p140 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
		error(get_errmsg("470"));
	}

	my $list;
	opendir(my $dir, qq|data/output/$FORM{"confid"}|);
	for my $filename(sort grep(!/^\.\.?$/, readdir($dir))) {
		my $filename_decoded = uri_unescape($filename);
		my $date_f = get_datetime((stat(qq|data/output/$FORM{"confid"}/$filename|))[9]);
		$list .= <<STR;
<tr>
	<td>$filename_decoded</td>
	<td>$date_f</td>
	<td>
		<input type="button" class="btn_s btn_submit" id="btn_submit_to_141" title="ダウンロード" value="ダウンロード" data-confid="$FORM{"confid"}" data-token_ignore="1" data-filename="$filename"><input type="button" class="btn_s btn_submit" id="btn_submit_to_142" title="削除" value="削除" data-confid="$FORM{"confid"}" data-filename="$filename" data-confirm="1" data-confirm_message="このファイルを削除します。一度削除すると元には戻せません。よろしいですか？">
	</td>
</tr>
STR
	}
	$list ||= qq|<tr><td colspan="3" class="c">(ファイルがありません)</td></tr>|;


	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"list" => $list,
	);
	exit;

}

1;
