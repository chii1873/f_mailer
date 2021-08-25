
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p163 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}$/) {
		json_output({
			"succeeded" => 0,
			"info" => "",
			"errmsg" => get_errmsg("470")
		});
	}

	if (! -d qq|data/key/$FORM{"confid"}/done|) {
		json_output({
			"succeeded" => 0,
			"info" => "",
			"errmsg" => get_errmsg("811", $FORM{"confid"})
		});
	}
	my $cnt = 0;
	opendir(my $dir, qq|data/key/$FORM{"confid"}/done|);
	foreach my $file(grep(/^(?:ID|KEY)_/, readdir($dir))) {
		unlink(qq|data/key/$FORM{"confid"}/done/$file|) or json_output({
			"succeeded" => 0,
			"info" => "",
			"errmsg" => get_errmsg("812", $FORM{"confid"}, $file)
		});
		$cnt++;
	}

	json_output({
		"succeeded" => 1,
		"info" => $cnt == 0 ? get_errmsg("813") : get_errmsg("814", $cnt),
		"errmsg" => "",
	});

	exit;

}

1;
