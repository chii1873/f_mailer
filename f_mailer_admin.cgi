#!/usr/bin/perl
#BEGIN{ print "Content-type: text/html\n\n"; $| =1; open(STDERR, ">&STDOUT"); }

use strict;
use lib qw(./module ./lib);
use vars qw($q %FORM %CONF %alt %ERRMSG);
use CGI;
use Unicode::Japanese;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Session;
use HTML::SimpleParse;
use LWP::Simple;
use Data::Dumper;
use JSON;
use Fcntl ':flock';
use Digest::MD5 qw(md5_hex);
use URI::Escape;
sub d { die Dumper($_[0]) }
$ENV{"PATH"} = "/usr/bin:/usr/sbin:/usr/local/bin:/bin";
require "f_mailer_lib.pl";
require "f_mailer_lib_admin.pl";
umask 0;

%CONF = (setver(), sysconf_read());
$CONF{"CGISESSID"} = get_cookie("CGISESSID");
$CONF{"session"} = new CGI::Session("driver:File", $CONF{"CGISESSID"}, { "Directory" => "./temp" });
$CONF{"__token"} = get_sid();
%ERRMSG = load_errmsg($CONF{"LANG_DEFAULT"} || "ja");
$CONF{"ERROR_TMPL"} = "tmpl/error.html";

### 2015/12/28 接続元制限
{
	my $remote_host = remote_host();
	my $ok = @{$CONF{"ALLOW_FROM"}} ? 0 : 1;
	foreach my $host(@{$CONF{"ALLOW_FROM"}}) {
		next if $host eq "";
		$ok = 1 if ($remote_host =~ /$host$/i or $ENV{"REMOTE_ADDR"} =~ /^$host$/);
	}
	if (!$ok) {
		error(get_errmsg("900", $remote_host, $ENV{"REMOTE_ADDR"}));
	}
}

$q = new CGI;
%FORM = decoding($q);

### CSRF対策 トークン発行処理
token_publish("admin");

login() if $FORM{"login"};
p("002") if $FORM{"p"} eq "002";
$CONF{"session"}->param("login_id") or p("001");

p($FORM{"p"} || "012");

sub error {

	printhtml("tmpl/admin_error.html", errmsg => join("", map { "<li>$_\n" }
	 map { html_output_escape($_) } @_),
	 (map { $_=>$CONF{$_} } keys %CONF), (map { $_=>$FORM{$_} } keys %FORM),
	);
	exit;

}

sub login {

	my @errmsg;
	if ($FORM{"login_id"} eq "") {
		push(@errmsg, get_errmsg("549"));
	}
	if ($FORM{"passwd"} eq "") {
		push(@errmsg, get_errmsg("550"));
	}
	p("001", @errmsg) if @errmsg;

	passwd_write() unless -e "data/passwd.cgi";
	my $password_encrypted = passwd_read($FORM{"login_id"});
	p("001", get_errmsg("551"))
	 if ($password_encrypted eq "" or passwd_compare($FORM{"passwd"}, $password_encrypted) == 0);

	$CONF{"session"}->param("login_id", $FORM{"login_id"});
	set_cookie("FORM_MAILER_ADMIN_CACHE", 30 * 86400,
	 ($FORM{"do_cache"} ? join("!!!", $FORM{"login_id"}, $FORM{"passwd"}) : ""));
	print "Location: f_mailer_admin.cgi\n\n";
	exit;

}

sub p {

	my $p = shift;
	my @errmsg = @_;

	if (-e "lib/p/p$p.pl") {
		require "lib/p/p$p.pl";
		eval "p$p(\"$p\", \@errmsg);";
		if ($@) {
			error("p$p: $@");
		}
	}
	exit;

}
