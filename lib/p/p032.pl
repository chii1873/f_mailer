
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p032 {

	my ($p) = @_;

	my @errmsg;

	if ($FORM{"SENDMAIL_FLAG"} eq "") {
		push(@errmsg, get_errmsg("530"));
	} elsif ($FORM{"SENDMAIL_FLAG"} == 0) {
		if ($FORM{"SENDMAIL"} eq "") {
			push(@errmsg, get_errmsg("531"));
		} elsif (! -e $FORM{"SENDMAIL"}) {
			push(@errmsg, get_errmsg("532"));
		}
	} elsif ($FORM{"SENDMAIL_FLAG"} == 1) {
		eval "use Net::SMTP;";
		push(@errmsg, get_errmsg("533", $@)) if $@;
		if ($FORM{"SMTP_HOST"} eq "") {
			push(@errmsg, get_errmsg("534"));
		} else {
			(my $smtp_host) = $FORM{"SMTP_HOST"} =~ /^([\w\.\-\_]*)$/;
			if ($smtp_host) {
				eval "use Net::SMTP;";
				my $smtp = Net::SMTP->new($smtp_host)
				 or push(@errmsg, get_errmsg("535", $FORM{"SMTP_HOST"}));
				### 2007-7-19 SMTP_AUTH対応
				if ($FORM{"USE_SMTP_AUTH"}) {
					eval qq{use MIME::Base64};
					push(@errmsg, get_errmsg("558")) if $@;
					eval qq{use Authen::SASL};
					push(@errmsg, get_errmsg("536")) if $@;
					if ($FORM{"SMTP_AUTH_ID"} eq "" or $FORM{"SMTP_AUTH_PASSWD"} eq "") {
						push(@errmsg, get_errmsg("537"));
					} else {
						$smtp->auth($FORM{"SMTP_AUTH_ID"}, $FORM{"SMTP_AUTH_PASSWD"})
						 or push(@errmsg, get_errmsg("538", $!));
					}
				}
			} else {
				push(@errmsg, get_errmsg("539", $FORM{"SMTP_HOST"}));
			}
		}
	}

	my $remote_host = remote_host();
	my $ok;
	foreach my $host(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $FORM{"ALLOW_FROM"})) {
		next if $host eq "";
		$ok = 1 if $remote_host =~ /$host$/i or $ENV{"REMOTE_ADDR"} =~ /^$host/;
	}
	if ($FORM{"ALLOW_FROM"} and !$ok) {
		push(@errmsg, get_errmsg("543"));
	}
	p("031", \@errmsg) if @errmsg;

	mk_sysconffile(%FORM);

	printhtml("tmpl/admin/$p.html");
	exit;

}
