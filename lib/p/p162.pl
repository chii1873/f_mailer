
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p162 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}$/) {
		json_output({
			"succeeded" => 0,
			"info" => "",
			"errmsg" => get_errmsg("470")
		});
	}

	my $filename = get_conffile_by_id($FORM{"confid"})
	 or json_output({
		"succeeded" => 0,
		"info" => "",
		"errmsg" => get_errmsg("006")
	});

	### $FORM{"USERDATA"}の内容チェック

	open(my $fh, ">", qq|data/key/$FORM{"confid"}/keys_$FORM{"confid"}.csv|)
	 or json_output({
		"succeeded" => 0,
		"info" => "",
		"errmsg" => get_errmsg("801", $!)
	});
	print $fh $FORM{"USERDATA"};
	close($fh);

	json_output({
		"succeeded" => 1,
		"info" => get_errmsg("802"),
		"errmsg" => ""
	});
	exit;

}

1;
