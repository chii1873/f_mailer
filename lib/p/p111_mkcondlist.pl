use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p111_mkcondlist {

	my %d = @_;

	open(my $fh, "<", "tmpl/111_cond_list.html");
	my $tmpl_cond_list = join("", <$fh>);
	close($fh);
	open($fh, "<", "tmpl/111_cond_list_skip.html");
	my $tmpl_cond_list_skip = join("", <$fh>);
	close($fh);
	open($fh, "<", "tmpl/111_cond_other.html");
	my $tmpl_cond_other = join("", <$fh>);
	close($fh);

	my $cond_list;
	my $cond_other;
	my @output_fields_pool = ("", "", {});
	my @confmeta = get_confmeta();
	my %skip = map { $_->[0] => 1 } @confmeta;
	my @caption = map { $_->[1] } @confmeta;;
	my $order = 0;
	my @order = split(/,/, $d{"OUTPUT_FIELDS"});
	my %order = map { $_ => 1 } @order;
	my $i = 0;
	for my $fname(split(/,/, $d{"cond"})) {
		if ($order{$fname}) {
			$output_fields_pool[2]{$fname} = 1;
		} else {
			$output_fields_pool[0] .= <<STR;
				<li data-fname="$fname">$d{"_cond_alt_$fname"}($fname)</li>
STR
		}

		if (! $skip{$fname}) {
			my $cond_list_ = $tmpl_cond_list;
			$cond_list_ =~ s/##i##/$i/g;
			$cond_list_ =~ s/##fname##/$fname/g;
			$cond_list_ =~ s/##type##/$d{"_cond_type_$fname"}/g;
			$cond_list .= $cond_list_;

			my $cond_other_ = $tmpl_cond_other;
			$cond_other_ =~ s/##i##/$i/g;
			$cond_other_ =~ s/##fname##/Unicode::Japanese->new($fname, "utf8")->get/ge;
#			$cond_other_ =~ s/##fname##/$fname/g;
# なぜかutf8フラグが立っている？
			$cond_other .= $cond_other_;
		} else {
			my $caption = shift @caption;
			my $cond_list_skip_ = $tmpl_cond_list_skip;
			$cond_list_skip_ =~ s/##i##/$i/g;
			$cond_list_skip_ =~ s/##fname##/$fname/g;
			$cond_list_skip_ =~ s/##caption##/$caption/g;
			$cond_list .= $cond_list_skip_;
		}

		$i++;
	}

	for my $fname(@order) {
		$fname = Unicode::Japanese->new($fname, "utf8")->get;
		next unless exists $output_fields_pool[2]{$fname};
		$output_fields_pool[1] .= <<STR;
				<li data-fname="$fname">$d{"_cond_alt_$fname"}($fname)</li>
STR

	}

	return (
		"cond_list" => $cond_list,
		"cond_other" => $cond_other,
		"output_fields_pool1" => $output_fields_pool[1],
		"output_fields_pool0" => $output_fields_pool[0],
	);

}

1;
