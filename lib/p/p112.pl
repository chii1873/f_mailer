
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p112 {

	my ($p, @errmsg) = @_;

	### セッションにデータ保存
	$CONF{"session"}->param("p111_data", \%FORM);

	require "p/p112_formcheck.pl";
	my @msg = p112_formcheck();
	if (@msg) {
		p("111", @msg);
	}

	p("113");
	exit;

}

1;
