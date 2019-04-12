
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p022 {

	my $p = shift;

	$FORM{"passwd"} or error(get_errmsg("400"));
	if ($FORM{"passwd"} ne $FORM{"passwd2"}) {
		p("021", get_errmsg("401"));
	}

	passwd_write($FORM{"passwd"});
	set_cookie("FORM_MAILER_ADMIN_CACHE", 30, $FORM{"passwd"}) if get_cookie("FORM_MAILER_ADMIN_CACHE");

	printhtml("tmpl/admin/$p.html");
	exit;

}
