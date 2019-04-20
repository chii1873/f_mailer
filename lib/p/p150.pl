
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p150 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
		error(get_errmsg("470"));
	}

	my $file = get_conffile_by_id($FORM{"confid"});
	if (-e "data/conf/$file.json") {
		my $conffile = uri_escape(qq|[$FORM{"confid"}]|.get_errmsg(901).".json");
		open(my $fh, "<", "data/conf/$file.json");
		print "Content-type: text/json\n";
		print qq|Content-disposition: attachment; filename*="utf-8''$conffile"\n\n|;
		print <$fh>;
		close($fh);
	} else {
		error(get_errmsg("612", $!, $FORM{"confid"}));
	}

	exit;

}

1;
