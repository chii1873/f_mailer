
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p171 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
		error(get_errmsg("470"));
	}
	my $filename_escaped = uri_escape( $FORM{"filename"} );
	if ($FORM{"filename"} eq "") {
		error(get_errmsg("580"));
	} elsif ($FORM{"filename"} =~ m#/#) {
		error(get_errmsg("581"));
	} elsif (! -e qq|data/att/$FORM{"confid"}/$filename_escaped|) {
		error(get_errmsg("582"));
	}

	open(my $fh, "<", qq|data/att/$FORM{"confid"}/$filename_escaped|)
	 or error(get_errmsg("583", $!));
	print qq|Content-type: application/octet-stream\n|;
	print qq|Content-disposition: attachment; filename*=utf-8''$filename_escaped\n\n|;
	print <$fh>;
	exit;

}

1;
