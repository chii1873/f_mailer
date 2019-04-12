
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p001 {

	my ($p, @errmsg) = @_;

	@FORM{qw(login_id passwd)} = get_cookie("FORM_MAILER_ADMIN_CACHE") unless @errmsg;
	$FORM{"do_cache"} = $FORM{"login_id"} ne "" ? 1 : 0;
	$FORM{"login"} = 1;

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
	);
	exit;

}

1;
