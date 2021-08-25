
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p022 {

	my $p = shift;
	my @errmsg;

	if ($FORM{"passwd"} eq "") {
		push(@errmsg, get_errmsg("402"));
	} else {
		my $password_encrypted = passwd_read($CONF{"session"}->param("login_id"));
		if (! passwd_compare($FORM{"passwd"}, $password_encrypted)) {
			push(@errmsg, get_errmsg("403"));
		}
	}

	if ($FORM{"passwd_new"} eq "") {
		push(@errmsg, get_errmsg("400"));
	} elsif ($CONF{"session"}->param("login_id") eq "admin" and $FORM{"passwd_new"} eq "12345") {
		push(@errmsg, get_errmsg("701"));
	} elsif ($FORM{"passwd_new"} ne $FORM{"passwd_new2"}) {
		push(@errmsg, get_errmsg("401"));
	}

	p("021", @errmsg) if @errmsg;

	passwd_write($CONF{"session"}->param("login_id"), $FORM{"passwd_new"});
	my ($cookie_id) = get_cookie("FORM_MAILER_ADMIN_CACHE");
	set_cookie("FORM_MAILER_ADMIN_CACHE", [ $CONF{"session"}->param("login_id"), $FORM{"passwd_new"} ], {
		"Expires" => 30 * 86400,
	}) if $cookie_id ne "";

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
	);
	exit;

}

1;
