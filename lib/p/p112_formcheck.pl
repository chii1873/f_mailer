sub p112_formcheck {

	my @msg;
	$FORM{"TITLE"} ||= $FORM{"SUBJECT"};
	$FORM{"LANG"} or push(@msg, "言語モードを選択してください。");
	my $form_tmpl_errmsg_ok = 0;
	if ($FORM{"CONFIRM_FLAG"} eq "") {
		push(@msg, get_errmsg("483"));
	} elsif ($FORM{"CONFIRM_FLAG"} == 2) {
		if ($FORM{"CONFIRM_TMPL"} eq "") {
			push(@msg, get_errmsg("484"));
		### 2007-7-19 http経由テンプレート読み込み対応
		} elsif ($FORM{"CONFIRM_TMPL"} =~ /^http/) {
			eval "use LWP::Simple;";
			error(get_errmsg("485", $@)) if $@;
			unless (get($FORM{"CONFIRM_TMPL"})) {
				push(@msg, get_errmsg("486", $!));
			}
		} elsif (! -e $FORM{"CONFIRM_TMPL"}) {
			push(@msg, get_errmsg("487"));
		}
	}
	if ($FORM{"ERROR_FLAG"} eq "") {
		push(@msg, get_errmsg("488"));
	} elsif ($FORM{"ERROR_FLAG"} == 1) {
		my $error_html;
		if ($FORM{"ERROR_TMPL"} eq "") {
			push(@msg, get_errmsg("489"));
		### 2007-7-19 http経由テンプレート読み込み対応
		} elsif ($FORM{"ERROR_TMPL"} =~ /^http/) {
			eval "use LWP::Simple;";
			error(get_errmsg("490", $@)) if $@;
			unless ($error_html = get($FORM{"ERROR_TMPL"})) {
				push(@msg, get_errmsg("491", $!));
			}
		} elsif (! -e $FORM{"ERROR_TMPL"}) {
			push(@msg, get_errmsg("492"));
		} else {
			if (open(my $fh, "<", $FORM{"ERROR_TMPL"})) {
				$error_html = join("", <$fh>);
				close($fh);
			} else {
				push(@msg, get_errmsg("493", $!));
			}
		}
		if ($error_html) {
			$error_html =~ /##errmsg##/ or $error_html =~ /<!--\s*errmsg\s*-->/
			 or push(@msg, get_errmsg("494", $!));
		}
	}
	if ($FORM{"THANKS_FLAG"} eq "") {
		push(@msg, get_errmsg("495"));
	} elsif ($FORM{"THANKS_FLAG"} == 0) {
		if ($FORM{"THANKS"} eq "") {
			push(@msg, get_errmsg("496"));
		}
	} elsif ($FORM{"THANKS_FLAG"} == 2) {
		if ($FORM{"THANKS_TMPL"} eq "") {
			push(@msg, get_errmsg("497"));
		### 2007-7-19 http経由テンプレート読み込み対応
		} elsif ($FORM{"THANKS_TMPL"} =~ /^http/) {
			eval {use LWP::Simple; };
			error(get_errmsg("498", $@)) if $@;
			unless (get($FORM{"THANKS_TMPL"})) {
				push(@msg, get_errmsg("499", $!));
			}
		} elsif (! -e $FORM{"THANKS_TMPL"}) {
			push(@msg, get_errmsg("500"));
		}
	}
	$FORM{"DENY_DUPL_SEND"} ||= 0;
	if ($FORM{"DENY_DUPL_SEND"}) {
		if ($FORM{"DENY_DUPL_SEND_MIN"} eq "") {
			push(@msg, get_errmsg("501"));
		} elsif ($FORM{"DENY_DUPL_SEND_MIN"} =~ /\D/) {
			push(@msg, get_errmsg("502"));
		}
	}
	$FORM{"SENDTO"} or push(@msg, get_errmsg("503"));
	for my $sendto(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $FORM{"SENDTO"})) {
		if (! is_email($sendto)) {
			push(@msg, get_errmsg("552", $sendto));
		}
	}
	for my $cc(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $FORM{"CC"})) {
		if (! is_email($cc)) {
			push(@msg, get_errmsg("553", $cc));
		}
	}
	for my $bcc(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $FORM{"BCC"})) {
		if (! is_email($bcc)) {
			push(@msg, get_errmsg("554", $bcc));
		}
	}

	$FORM{SENDFROM} or push(@msg, get_errmsg("504"));
	$FORM{SUBJECT} or push(@msg, get_errmsg("505"));
	if ($FORM{"ATTACH_SIZE_MAX"} =~ /\D/) {
		push(@msg, get_errmsg("506"));
	}
	if ($FORM{"ATTACH_TSIZE_MAX"} =~ /\D/) {
		push(@msg, get_errmsg("507"));
	}
	if ($FORM{"MAIL_FORMAT_TYPE"} eq "") {
		push(@msg, get_errmsg("508"));
	} elsif ($FORM{"MAIL_FORMAT_TYPE"} == 0 and !$FORM{"FORMAT"}) {
		push(@msg, get_errmsg("509"));
	}
	if ($FORM{"OFT"} =~ /\D/) {
		push(@msg, get_errmsg("510"));
	} elsif ($FORM{"OFT"} < 0 or $FORM{"OFT"} > 40) {
		push(@msg, get_errmsg("511"));
	}
	$FORM{"AUTO_REPLY"} ||= 0;
	if ($FORM{"AUTO_REPLY"}) {
		for my $cc(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $FORM{"REPLY_CC"})) {
			if (! is_email($cc)) {
				push(@msg, get_errmsg("555", $cc));
			}
		}
		for my $bcc(split(/[ \t]*(?:\r\n|\r|\n|,)[ \t]*/, $FORM{"REPLY_BCC"})) {
			if (! is_email($bcc)) {
				push(@msg, get_errmsg("556", $bcc));
			}
		}
		$FORM{"REPLY_SENDFROM"} ||= $FORM{"SENDFROM"};
		$FORM{"REPLY_ENVELOPE_ADDR"} ||= $FORM{"ENVELOPE_ADDR"};
		$FORM{"REPLY_SUBJECT"} or push(@msg, get_errmsg("512"));
		if ($FORM{"REPLY_MAIL_FORMAT_TYPE"} eq "") {
			push(@msg, get_errmsg("513"));
		} elsif ($FORM{"REPLY_MAIL_FORMAT_TYPE"} == 0 and !$FORM{"REPLY_FORMAT"}) {
			push(@msg, get_errmsg("514"));
		}
		if ($FORM{"REPLY_OFT"} =~ /\D/) {
			push(@msg, get_errmsg("515"));
		} elsif ($FORM{"REPLY_OFT"} < 0 or $FORM{"REPLY_OFT"} > 40) {
			push(@msg, get_errmsg("516"));
		}
	}
	$FORM{"FILE_OUTPUT"} ||= 0;
	if ($FORM{"FILE_OUTPUT"}) {
		if ($FORM{"OUTPUT_FILENAME"} eq "") {
			push(@msg, get_errmsg("517"));
		} elsif ($FORM{"OUTPUT_FILENAME"} eq ".." or $FORM{"OUTPUT_FILENAME"} =~ m#/#) {
			push(@msg, get_errmsg("557"));
		}
		$FORM{"OUTPUT_SEPARATOR"} ||= 0;
		$FORM{"FIELD_SEPARATOR"} = " " if $FORM{"FIELD_SEPARATOR"} eq "";
	}
#	eval qq|use strict; my \$sub = sub { $FORM{"EXT_SUB"} };|;
#	if ($@) {
#		push(@msg, "付加的に実行したいコード1のコードが不正です。: $@");
#	}
#	eval qq|use strict; my \$sub = sub { $FORM{"EXT_SUB2"} };|;
#	if ($@) {
#		push(@msg, "付加的に実行したいコード2のコードが不正です。: $@");
#	}

	my @checklist = get_checklist();
	my %checkname = map { $_->{"name"} => $_->{"dsp"} } @checklist;
	my %fields = map { $_ => 1 } split(/,/, $FORM{"cond"});
	my @confmeta = get_confmeta();
	my %skip = map { $_->[0] => 1 } @confmeta;
	my $type_empty;
	foreach my $f(split(/,/, $FORM{"cond"})) {
#        $FORM{"_cond_alt_$f"} ||= $f;
		next if $skip{$f};
		$type_empty = 1 if $FORM{"_cond_type_$f"} eq "";
		if ($f eq "EMAIL") {
			$FORM{"_cond_email_$f"}
			 or push(@msg, get_errmsg("520", $f, $checkname{"email"}));
		}
		if ($FORM{"_cond_type_$f"} eq "file") {
			unless ($FORM{"_cond_attach_$f"}) {
				push(@msg, get_errmsg("521", $f, $checkname{"attach"}));
			}
			my $check;
			foreach (grep { $_->{"name"} ne "alt" and $_->{"name"} ne "attach" and $_->{"name"} ne "required" } @checklist) {
				$check = 1 if $FORM{qq|_cond_$_->{"name"}_$f|};
			}
			if ($check) {
				push(@msg, get_errmsg("522", $f, $checkname{"attach"}, $checkname{"required"}));
			}
		} elsif ($FORM{"_cond_attach_$f"}) {
			my $check;
			foreach (grep { $_->{"name"} ne "alt" and  $_->{"name"} ne "attach" and $_->{"name"} ne "required" } @checklist) {
				$check = 1 if $FORM{qq|_cond_$_->{"name"}_$f|};
			}
			if ($check) {
				push(@msg, get_errmsg("522", $f, $checkname{"attach"}, $checkname{"required"}));
			}
		} else {
			if ($FORM{"_cond_compare_$f"}) {
				$fields{$f} or push(@msg, get_errmsg("523", $f, $checkname{"compare"}, "${f}2"));
			}
		}
	}
	if ($type_empty) {
		push(@msg, get_errmsg("524"));
	}
	@msg;

}

1;
