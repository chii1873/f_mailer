
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p141 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
		error(get_errmsg("470"));
	}
	if ($FORM{"filename"} eq "") {
		error(get_errmsg("580"));
	} elsif ($FORM{"filename"} =~ m#/#) {
		error(get_errmsg("581"));
	} elsif (! -e qq|data/output/$FORM{"confid"}/$FORM{"filename"}|) {
		error(get_errmsg("582"));
	}

	open(my $fh, "<", qq|data/output/$FORM{"confid"}/$FORM{"filename"}|)
	 or error(get_errmsg("583", $!));
	my $filename_escaped = uri_escape( $FORM{"filename"} );
	print qq|Content-type: application/octet-stream\n|;
	print qq|Content-disposition: attachment; filename*="utf-8''$filename_escaped"\n\n|;
	print <$fh>;
	exit;

}

1;
