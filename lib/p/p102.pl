
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p102 {

	my ($p, @errmsg) = @_;

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"conflist" => scalar(get_conflist()),
	);
	exit;

}

1;
