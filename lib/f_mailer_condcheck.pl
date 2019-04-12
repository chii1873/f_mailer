sub condcheck_init {


	my @order;
	open(my $fh, "<", "data/check.txt")
	 or error("Failed to open check.txt: $!");
	while (<$fh>) {
		my($f) = split(/\t/, $_, 2);
		push(@order, $f);
	}

	return (

		"__order" => \@order,

		"compare" => sub {
			my($f_name, $alt_name, $f_value, $cond) = @_;
			my @errmsg;
			if ($f_value ne "" and $cond ne "" and $f_value ne $cond) {
				push(@errmsg, set_errmsg(key=>"compare", f_name=>($alt_name or $f_name)));
			}
			($f_value, @errmsg);
		},
		"d_only" => sub {
			my($f_name, $alt_name, $f_value) = @_;
			my @errmsg;
			if ($f_value =~ /\D/) {
				push(@errmsg, set_errmsg(key=>"d_only", f_name=>($alt_name or $f_name)));
			}
			($f_value, @errmsg);
		},
		"deny_rel" => sub {
			my($f_name, $alt_name, $f_value) = @_;
			my @errmsg;
			my $ret = mojichk($FORM{$f_name}, ($alt_name or $f_name));
			push(@errmsg, $ret) if $ret;
			($f_value, @errmsg);
		},
		"email" => sub {
			my($f_name, $alt_name, $f_value, $cond) = @_;
			my @errmsg;
			if ($f_value and ! is_email($f_value)) {
				push(@errmsg, set_errmsg(key=>"email", f_name=>($alt_name or $f_name)));
			}
			($f_value, @errmsg);
		},
		"h2z" => sub {
			my($f_name, $alt_name, $f_value) = @_;
			return h2z($f_value);
		},
		"h2z_kana" => sub {
			my($f_name, $alt_name, $f_value) = @_;
			return h2z_kana($f_value);
		},
		"hira2kata" => sub {
			my($f_name, $alt_name, $f_value) = @_;
			return Unicode::Japanese->new($f_value, "utf8")->hira2kata->get;
		},
		"hira_only" => sub {
			my($f_name, $alt_name, $f_value) = @_;
			my $f_value_ = Unicode::Japanese->new($f_value, "utf8")->getu;
			my @errmsg;
			unless ($f_value_ =~ /^[\p{InHiragana}\x{3000}\x{30fc}]*$/o) { # ひらがな、全角スペース(　)、長音記号(ー)
				push(@errmsg, set_errmsg(key=>"hira_only", f_name=>($alt_name or $f_name)));
			}
			($f_value, @errmsg);
		},
		"kata2hira" => sub {
			my($f_name, $alt_name, $f_value) = @_;
			return Unicode::Japanese->new($f_value, "utf8")->kata2hira->get;
		},
		"kata_only" => sub {
			my($f_name, $alt_name, $f_value) = @_;
			my $f_value_ = Unicode::Japanese->new($f_value, "utf8")->getu;
			my @errmsg;
			unless ($f_value_ =~ /^[\p{InKatakana}\x{3000}\x{30a0}\x{30fc}]*$/o) { # カタカナ、全角スペース(　)、二重ハイフン(゠)、長音記号(ー)
				push(@errmsg, set_errmsg(key=>"kata_only", f_name=>($alt_name or $f_name)));
			}
			($f_value, @errmsg);
		},
		"max" => sub {
			my($f_name, $alt_name, $f_value, $cond, $type, $d_only) = @_;
			my @errmsg;
			if ($d_only) {
				if ($FORM{$f_name} ne '' and $FORM{$f_name} > $cond) {
					push(@errmsg, set_errmsg(key=>"max", f_name=>($alt_name or $f_name), cond=>$cond));
				}
			} elsif ($type eq "select" or $type eq "checkbox") {
				if (scalar(split(/\!\!\!/, $f_value)) > $cond) {
					push(@errmsg, set_errmsg(key=>"num_max", f_name=>($alt_name or $f_name), cond=>$cond));
				}
			} else {
				if (length($f_value) > $cond) {
					push(@errmsg, set_errmsg(key=>"len_max", f_name=>($alt_name or $f_name), cond=>$cond, cond2=>int($cond/2)));
				}
			}
			($f_value, @errmsg);
		},
		"min" => sub {
			my($f_name, $alt_name, $f_value, $cond, $type, $d_only) = @_;
			my @errmsg;
			if ($d_only) {
				if ($f_value ne '' and $f_value < $cond) {
					push(@errmsg, set_errmsg(key=>"min", f_name=>($alt_name or $f_name), cond=>$cond));
				}
			} elsif ($type eq "select" or $type eq "checkbox") {
				if (scalar(split(/\!\!\!/, $f_value)) < $cond) {
					push(@errmsg, set_errmsg(key=>"num_min", f_name=>($alt_name or $f_name), cond=>$cond));
				}
			} else {
				if (length($f_value) < $cond) {
					push(@errmsg, set_errmsg(key=>"len_min", f_name=>($alt_name or $f_name), cond=>$cond));
				}
			}
			($f_value, @errmsg);
		},
		"regex" => sub {
			my($f_name, $alt_name, $f_value, $cond) = @_;
			my @errmsg;
			eval {
				if ($f_value =~ /$cond/) {
					push(@errmsg, set_errmsg(key=>"regex", f_name=>($alt_name or $f_name)));
				}
			},
			push(@errmsg, set_errmsg(key=>"regex_eval_error",
			 f_name=>($alt_name or $f_name), eval=>$@)) if $@;
			($f_value, @errmsg);
		},
		"regex2" => sub {
			my($f_name, $alt_name, $f_value, $cond) = @_;
			my @errmsg;
			eval {
				if ($f_value !~ /$cond/) {
					push(@errmsg, set_errmsg(key=>"regex2", f_name=>($alt_name or $f_name)));
				}
			},
			push(@errmsg, set_errmsg(key=>"regex_eval_error",
			 f_name=>($alt_name or $f_name), eval=>$@)) if $@;
			($f_value, @errmsg);
		},
		"required" => sub {
			my($f_name, $alt_name, $f_value, $cond, $type, $d_only, $exists) = @_;
			my @errmsg;
			if ($type eq "file" and ! $exists) {
				push(@errmsg, set_errmsg(key=>"required",
				 f_name=>($alt_name or $f_name),
				 str=>$CONF{errmsg}{"required_upload"})
				);
			} elsif ($type ne "file" and $f_value eq '') {
				push(@errmsg, set_errmsg(key=>"required",
				 f_name=>($alt_name or $f_name),
				 str=>$CONF{errmsg}{$type =~ /^(?:radio|checkbox|select)$/ ? "required_choose" : "required_input" })
				);
			}
			($f_value, @errmsg);
		},
		"trim" => sub {
			my($f_name, $alt_name, $f_value) = @_;
			$f_value =~ s/[\r\n]+//g;
			($f_value);
		},
		"trim2" => sub {
			my($f_name, $alt_name, $f_value) = @_;
			(trim($f_value)); # String::Util::trim 使用
		},
		"url" => sub {
			my($f_name, $alt_name, $f_value) = @_;
			my @errmsg;
			if ($f_value and $f_value !~ m#(s?https?://[-_.!~*'()a-zA-Z0-9;/?:\@&=+\$,%\#]+)#) {
				push(@errmsg, set_errmsg(key=>"url", f_name=>($alt_name or $f_name)));
			}
			($f_value, @errmsg);
		},
		"z2h" => sub {
			my($f_name, $alt_name, $f_value) = @_;
			return z2h($f_value);
		},

	);

}

1;
