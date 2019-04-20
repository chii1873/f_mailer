
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p031 {

	my ($p, @errmsg) = @_;

	%FORM = (%FORM, @errmsg ? () : %CONF);
	if (ref $FORM{"ALLOW_FROM"} eq "ARRAY") {
		$FORM{"ALLOW_FROM"} = join("\n", @{$FORM{"ALLOW_FROM"}});
	}
	if (ref $FORM{"SENDFROM_SKIP"} eq "ARRAY") {
		$FORM{"SENDFROM_SKIP"} = join("\n", @{$FORM{"SENDFROM_SKIP"}});
	}

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"langlist" => get_langlist_select(),
		"rh" => remote_host(),
		"ip" => $ENV{"REMOTE_ADDR"},
	);
	exit;

}

1;
