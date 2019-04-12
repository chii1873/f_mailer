
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p002 {

	my ($p, @errmsg) = @_;

	$CONF{"session"}->param("login_id", "");

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
	);
	exit;

}

1;
