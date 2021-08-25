
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p160 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}$/) {
		error(get_errmsg("470"));
	}

	my $filename = get_conffile_by_id($FORM{"confid"})
	 or json_output({
		"succeeded" => 0,
		"info" => "",
		"errmsg" => get_errmsg("006")
	});

	my %d = conf_read_to_temp($FORM{"confid"});

	if (! -e qq|data/key/$FORM{"confid"}/keys_$FORM{"confid"}.csv|) {
		open(my $fh, ">", qq|data/key/$FORM{"confid"}/keys_$FORM{"confid"}.csv|) or error(get_errmsg("801", $!));
		close($fh);
	}

	open(my $fh, "<", qq|data/key/$FORM{"confid"}/keys_$FORM{"confid"}.csv|) or error(get_errmsg("800", $!));
	$FORM{"USERDATA"} = join("", <$fh>);
	close($fh);

	printhtml_admin("$p.html",
		"label" => $d{"label"},
		"confid" => $FORM{"confid"},
		"errmsg" => \@errmsg,
	);

	exit;

}

1;
