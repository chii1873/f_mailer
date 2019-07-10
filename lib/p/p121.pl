
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p121 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
		error(get_errmsg("470"));
	}

	%FORM = (%FORM, @errmsg ? %{ $CONF{"session"}->param("p111_data") } : conf_read_to_temp($FORM{"confid"}));

	require "p/p111_mkcondlist.pl";
	my %tmpl = p111_mkcondlist(%FORM);

	printhtml_admin("111.html",
		"errmsg" => \@errmsg,
		"p_next" => 122,
		"langlist" => get_langlist_select(),
		"confid" => $FORM{"confid"},
		"confid_dsp" => $FORM{"confid"},
		"cond_list" => $tmpl{"cond_list"},
		"cond_other" => $tmpl{"cond_other"},
		"output_fields_pool1" => $tmpl{"output_fields_pool1"},
		"output_fields_pool0" => $tmpl{"output_fields_pool0"},
	);
	exit;

}

1;
