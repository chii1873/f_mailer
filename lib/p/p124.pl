
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p124 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
		error(get_errmsg("470"));
	}

	my %conf = conf_read_to_temp($FORM{"confid"});

	open(my $fh, "<", qq|data/serial/$FORM{"confid"}|) or error(get_errmsg("450", $!));
	my $serial = <$fh> || "-";
	close($fh);

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"confid" => $FORM{"confid"},
		"label"  => $conf{"label"},
		"SERIAL" => $serial,
	);
	exit;

}

1;
