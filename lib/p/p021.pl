
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p021 {

	my ($p, @errmsg) = @_;

	printhtml("tmpl/admin/$p.html", \@errmsg);
	exit;

}
