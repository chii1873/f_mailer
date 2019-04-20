
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p111 {

	my ($p, @errmsg) = @_;

	%FORM = (%FORM, %{ $CONF{"session"}->param("p111_data") });

	require "p/p111_mkcondlist.pl";
	my %tmpl = p111_mkcondlist(%FORM);

	printhtml_admin("111.html",
		"errmsg" => \@errmsg,
		"p_next" => 112,
		"langlist" => get_langlist_select(),
		"confid" => "",
		"confid_dsp" => "(新規追加)",
		"cond_list" => $tmpl{"cond_list"},
		"cond_other" => $tmpl{"cond_other"},
		"output_fields_pool1" => $tmpl{"output_fields_pool1"},
		"output_fields_pool0" => $tmpl{"output_fields_pool0"},
	);
	exit;

}

1;
