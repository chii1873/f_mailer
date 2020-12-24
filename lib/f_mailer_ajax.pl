
use strict;
use vars qw($q %FORM %CONF $name_list_ref %alt %ERRMSG);

sub ajax_checkvalues {

	my @errmsg = checkvalues("ajax" => 1);
	print "Content-Type: application/json\n\n";
	print to_json({
		"errmsg" => [ @errmsg ],
		"FORM_TMPL_ERRMSG_DISPLAY" => $CONF{"FORM_TMPL_ERRMSG_DISPLAY"},
		"ERRMSG_STYLE_LI" => $CONF{"ERRMSG_STYLE_LI"},
		"ERRMSG_STYLE_LI_CLASS" => $CONF{"ERRMSG_STYLE_LI_CLASS"},
		"ERRMSG_STYLE_UL" => $CONF{"ERRMSG_STYLE_UL"},
		"ERRMSG_STYLE_UL_CLASS" => $CONF{"ERRMSG_STYLE_UL_CLASS"},
		"ERRMSG_STYLE_UL_ID" => $CONF{"ERRMSG_STYLE_UL_ID"},
	});
	exit;

}

sub ajax_delete {

	my @msg;
	my %exists = ajax_file_check("thru"=>1);
	if ($exists{$FORM{"ajax_delete"}}) {
		my $file = $exists{$FORM{"ajax_delete"}}{"filename"};
		if (-e "temp/$file") {
			unlink("temp/$file") or ajax_error(get_errmsg("100", $!));
		}
	}
	ajax_done();

}

sub ajax_done {

	my $alert = shift;
	if ($alert ne "") {
		$alert =~ s/"/&quot;/;
		$alert = <<STR;
	alert("$alert");
STR
	}
	printhtml("./tmpl/upload_done.html",
	 "alert"=>$alert,
	);
	exit;

}

sub ajax_error {

	my $errmsg = shift;
#d($errmsg);
	ajax_done($errmsg);

}

sub ajax_file_check {

	my %opt = @_;

	my %ATTACH_FIELDNAME = map { $_ => { "name" => "", "size" => 0 } } @{$CONF{"ATTACH_FIELDNAME"}};
	$FORM{"TEMP"} ||= sprintf("%s_%s", $FORM{"CONFID"}, $CONF{"session"}->id());

	my %exists;
	opendir(my $dir, "./temp") or ajax_error(get_errmsg("103", $!));
	my $size_total = 0;
	for my $f(grep(/^$FORM{"TEMP"}-/, readdir($dir))) {
		my($temp, $field_name, $file_name) = split(/-/, $f, 3);
#		$field_name = uri_unescape($field_name);
#		$file_name = uri_unescape($file_name);
		next unless $ATTACH_FIELDNAME{$field_name};
		my $file_size = (stat("temp/$f"))[7];
		$size_total += $file_size;
		$exists{$field_name} = {
			"name" => Unicode::Japanese->new(uri_unescape($file_name), "utf8")->getu,
			"filename" => $f,
			"size" => $file_size,
		};
		$FORM{$field_name} = uri_unescape($file_name);
	}
	closedir($dir);

	if ($opt{"thru"}) {
		return %ATTACH_FIELDNAME, %exists, "__TOTAL__" => $size_total, "TEMP" => $FORM{"TEMP"};
	} else {
		print "Content-Type: application/json\n\n";
		print encode_json({ %ATTACH_FIELDNAME, %exists, "__TOTAL__" => $size_total, "TEMP" => $FORM{"TEMP"} });
		exit;
	}

}

sub ajax_init {

	ajax_done();

}

sub ajax_token {

	print "Content-Type: application/json\n\n";
	print json_encode({ "__token" => $CONF{"__token"} });
	exit;

}

sub ajax_upload {

	my $ext = lc((split(/\./, $FORM{$FORM{"ajax_upload"}}))[-1]);
	my %ext = map { lc($_) => 1 } @{$CONF{"ATTACH_EXT"}};

	my $filename = (split(/[\\\/]/, $FORM{$FORM{"ajax_upload"}}))[-1];
	if ($ext{$ext}) {
		$FORM{"TEMP"} ||= sprintf("%s_%s", $FORM{"CONFID"}, $CONF{"session"}->id());;
		my $errmsg = imgsave($FORM{"TEMP"}, $FORM{"ajax_upload"});
		ajax_error($errmsg) if $errmsg;

		### アップロードしたファイルの単体/合計サイズ超過チェック
		my %exists = ajax_file_check("thru"=>1);
		if ($exists{$FORM{"ajax_upload"}} and $CONF{"ATTACH_SIZE_MAX"} and $exists{$FORM{"ajax_upload"}}{"file_size"} > $CONF{"ATTACH_SIZE_MAX"} * 1024) {
			my $file = $exists{$FORM{"ajax_upload"}}{"filename"};
			if (-e "temp/$file") {
				unlink("temp/$file") or ajax_error(get_errmsg("100", $!));
			}
			ajax_error(get_errmsg("101", $alt{$FORM{"ajax_upload"}}, $CONF{"ATTACH_SIZE_MAX"}));
		}
		if ($CONF{"ATTACH_TSIZE_MAX"} and $exists{"__TOTAL__"} > $CONF{"ATTACH_TSIZE_MAX"} * 1024) {
			my $file = $exists{$FORM{"ajax_upload"}}{"filename"};
			if (-e "temp/$file") {
				unlink("temp/$file") or ajax_error(get_errmsg("100", $!));
			}
			ajax_error(get_errmsg("102", $CONF{"ATTACH_TSIZE_MAX"}));
		}

	} else {
		ajax_error(get_errmsg("100", ($alt{$FORM{"ajax_upload"}} or $FORM{"ajax_upload"}), $filename));
	}

	ajax_done();

}

1;
