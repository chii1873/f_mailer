
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p021 {

	my ($p, @errmsg) = @_;

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
	);
	exit;

}

1;
