
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p012 {

	my ($p, @errmsg) = @_;

	temp_del(2);  ### 2時間経過したtempファイルを削除

	my $list;
	my %lang = map { $_->[0] => $_->[1] } get_langlist();
	my %errmsg = map { $_ => get_errmsg($_) } (570..574);
	foreach my $conf(get_conflist()) {
		my($conf_id, $filename, $label, $lang, $date) = map { $conf->{$_} } qw(id file label lang date);
		$lang ||= "ja";
		my $last_update = $date || get_datetime((stat("data/conf/$filename"))[9]);
		$list .= <<STR;
<tr>
	<td>$label</td>
	<td>$conf_id</td>
	<td>$filename</td>
	<td>ext_$filename</td>
	<td class="nowrap">($lang)$lang{$lang}</td>
	<td class="nowrap">$last_update</td>
	<td class="nowrap">
		<button onclick="location.href='f_mailer_admin.cgi?confform=1;conf_id=$conf_id'">$errmsg{570}</button>
		<button onclick="location.href='f_mailer_admin.cgi?confserial=1;conf_id=$conf_id'">$errmsg{571}</button>
		<button onclick="if(confirm('$errmsg{572}')){location.href='f_mailer_admin.cgi?del=1;conf_id=$conf_id'}">$errmsg{573}</button>
	</td>
</tr>
STR
	}
	$list ||= qq|<tr><td colspan="7" class="c">$errmsg{574}</td></tr>|;

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"list" => $list,
	);
	exit;

}

1;
