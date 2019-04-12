
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p111 {

	my ($p, @errmsg) = @_;

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"langlist" => get_langlist_select(),
	);
	exit;

}

1;
