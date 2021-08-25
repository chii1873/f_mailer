
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p170 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}$/) {
		error(get_errmsg("470"));
	}

	my %d = conf_read_to_temp($FORM{"confid"});

	my $list;
	my $i = 1;
	opendir(my $dir, qq|data/att/$FORM{"confid"}|);
	for my $filename(map { $_->[0] } sort { $b->[1] <=> $a->[1] or $a->[0] cmp $b->[0] } map { [$_, (stat(qq|data/att/$FORM{"confid"}/$_|))[9] ] } grep(!/^\.\.?$/, readdir($dir))) {
		my $date_f = get_datetime((stat(qq|data/att/$FORM{"confid"}/$filename|))[9]);
		(my $filename_decoded = $filename) =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg; 
		$list .= <<STR;
<tr>
	<td class="c"><input type="checkbox" name="chk" value="$filename_decoded" id="chk-$i"></td>
	<td><label for="chk-$i">$filename_decoded</label></td>
	<td>$date_f</td>
	<td>
		<input type="button" class="btn_s btn_submit" id="btn_submit_to_171" title="ダウンロード" value="ダウンロード" data-confid="$FORM{"confid"}" data-token_ignore="1" data-filename="$filename_decoded"><input type="button" class="btn_s btn_submit" id="btn_submit_to_172" title="削除" value="削除" data-confid="$FORM{"confid"}" data-filename="$filename_decoded" data-confirm="1" data-confirm_message="このファイルを削除します。一度削除すると元には戻せません。よろしいですか？">
	</td>
</tr>
STR
		$i++;
	}
	$list ||= qq|<tr><td colspan="4" class="c">(ファイルがありません)</td></tr>|;

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"label" => $d{"label"},
		"confid" => $FORM{"confid"},
		"list" => $list,
	);
	exit;

}

1;
