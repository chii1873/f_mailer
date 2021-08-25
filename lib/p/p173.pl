
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p173 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
		error(get_errmsg("470"));
	}

	if ($FORM{"chk"} eq "") {
		p(170, get_errmsg("587"));
	}

	my $zip = Archive::Zip->new();
	for my $filename(split(/\!\!\!/, $FORM{"chk"})) {
		my $filename_escaped = uri_escape( $filename );
		if (! -e qq|data/att/$FORM{"confid"}/$filename_escaped|) {
			error(get_errmsg("582"));
		}
		### 暫定的にWindows用にファイル名はCP932コードに変換
		### 後にMacの場合はUTF8のままにする対応をする
		$zip->addFile( qq|data/att/$FORM{"confid"}/$filename_escaped|, Unicode::Japanese->new($filename, "utf8")->sjis );
	}

	(my $dt = get_datetime()) =~ s/\D//g;
	my $output_file_j = uri_escape(qq|アップロード済ファイル($FORM{"confid"})_$dt.zip|);
	print qq|Content-type: application/octet-stream\n|;
	print qq|Content-disposition: attachment; filename*="utf-8''$output_file_j"\n\n|;
	$zip->writeToFileHandle(*STDOUT, 0);
	exit;

}

1;
