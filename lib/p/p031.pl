
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p031 {

	my ($p, @errmsg) = @_;

	%FORM = (%FORM, @errmsg ? () : %CONF);

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"langlist" => get_langlist_select($CONF{"LANG_DEFAULT"}),
		"rh" => remote_host(),
		"ip" => $ENV{"REMOTE_ADDR"},
	);
	exit;

}

1;
