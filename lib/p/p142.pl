
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p142 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
		error(get_errmsg("470"));
	}
	if ($FORM{"filename"} eq "") {
		error(get_errmsg("584"));
	} elsif ($FORM{"filename"} =~ m#/#) {
		error(get_errmsg("585"));
	} elsif (! -e qq|data/output/$FORM{"confid"}/$FORM{"filename"}|) {
		error(get_errmsg("586"));
	}

	unlink(qq|data/output/$FORM{"confid"}/$FORM{"filename"}|);
	p("140");
	exit;

}

1;
