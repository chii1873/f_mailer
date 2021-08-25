
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p172 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
		error(get_errmsg("470"));
	}
	my $filename_escaped = uri_escape( $FORM{"filename"} );
	if ($FORM{"filename"} eq "") {
		error(get_errmsg("584"));
	} elsif ($FORM{"filename"} =~ m#/#) {
		error(get_errmsg("585"));
	} elsif (! -e qq|data/att/$FORM{"confid"}/$filename_escaped|) {
		error(get_errmsg("586"));
	}

	unlink(qq|data/att/$FORM{"confid"}/$filename_escaped|);
	p("170");
	exit;

}

1;
