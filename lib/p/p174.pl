
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p174 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
		error(get_errmsg("470"));
	}

	if ($FORM{"chk"} eq "") {
		p(170, get_errmsg("588"));
	}

	for my $filename(split(/\!\!\!/, $FORM{"chk"})) {
		my $filename_escaped = uri_escape( $filename );
		if (! -e qq|data/att/$FORM{"confid"}/$filename_escaped|) {
			error(get_errmsg("582"));
		}
		unlink(qq|data/att/$FORM{"confid"}/$filename_escaped|)
		 or error(get_errmsg("589"), $filename, $!);
	}

	p("170");
	exit;

}

1;
