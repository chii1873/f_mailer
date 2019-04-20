
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p104 {

	my ($p, @errmsg) = @_;

	### データをセッションに保存する
	$CONF{"session"}->param("p111_data", \%FORM);

	my $content;
	if ($FORM{"import_method"} !~ /^[12]$/) {
		p104_error(get_errmsg("440"));
	}

	if ($FORM{"import_method"} == 1) {
		if ($FORM{"import_method_url"} eq "") {
			p104_error(get_errmsg("441"));
		} elsif (! is_url($FORM{"import_method_url"})) {
			p104_error(get_errmsg("442"));
		}
		$content = get($FORM{"import_method_url"});
		if ($content eq "") {
			p104_error(get_errmsg("443"));
		}
	} elsif ($FORM{"import_method"} == 2) {
		$content = $FORM{"import_method_source"};
		if ($content eq "") {
			p104_error(get_errmsg("444"));
		}
	}

	my %cond_exists = map { $_ => 1 } split(/,/, $FORM{"cond"});

	my $p = new HTML::SimpleParse($content);
	my %is_formtag = map { $_ => 1 } qw(input select textarea);
	my %tag;
	my @tag_order;
	my %reserved = map { $_ => 1 } reserved_words();

	my %d;
	for ($p->tree) {
		my %c = %$_;
		next if $c{"type"} ne "starttag";
		@c{qw(tagname content)} = split(/\s+/, $c{"content"}, 2);
		next unless $is_formtag{lc($c{"tagname"})};
		my %h = $p->parse_args( $c{"content"} );
		next if $reserved{$h{"NAME"}};
		next if lc($h{"TYPE"}) =~ /^(?:reset|submit|button|image)$/;
		push(@tag_order, $h{"NAME"}) unless exists $tag{$h{"NAME"}};
		$tag{$h{"NAME"}} = 1;
		$d{qq|_cond_type_$h{"NAME"}|} = lc($c{"tagname"}) ne "input" ? lc($c{"tagname"}) : (lc($h{"TYPE"}) || 'text');
		$d{qq|_cond_email_$h{"NAME"}|} = 1 if $h{"NAME"} eq "EMAIL";
		$d{qq|_cond_attach_$h{"NAME"}|} = 1 if $d{qq|_cond_type_$h{"NAME"}|} eq "file";
	}
	$d{"cond"} = join(",", @tag_order, map { $_->[0] } get_confmeta());

	p104_error(get_errmsg("445")) unless @tag_order;

	%FORM = (%FORM, %d);
#p104_error(join(", ", map { $_ ."=". $FORM{$_} } keys %FORM));
	require "p/p111_mkcondlist.pl";
	my %tmpl = p111_mkcondlist(%FORM);

### 返したあとで、OUTPUT_FIELDSなど更新
### セッションに保存しなくてよい？

	print "Content-type: text/json\n\n";
	print json_encode({
		"succeeded" => 1,
		"cond_list" => get_output_form_admin($tmpl{"cond_list"}, %FORM),
		"cond_other" => get_output_form_admin($tmpl{"cond_other"}, %FORM),
		"output_fields_pool1" => $tmpl{"output_fields_pool1"},
		"output_fields_pool0" => $tmpl{"output_fields_pool0"},
		"cond" => $d{"cond"},
	});
	exit;

}

sub p104_error {

	my @errmsg = @_;
	print "Content-type: text/json\n\n";
	print json_encode({ "succeeded" => 0, "errmsg" => \@errmsg });
	exit;

}

1;
