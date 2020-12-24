
use strict;
use vars qw($q %FORM %CONF %alt $name_list_ref %ERRMSG);

sub p125 {

	my ($p, @errmsg) = @_;

	if ($FORM{"confid"} !~ /^\d{6}|sample$/) {
		error(get_errmsg("470"));
	}

	if ($FORM{"SERIAL"} !~ /^(?:[\+\-])?\d+$/) {
		p("124", get_errmsg("461"));
	}

	my %conf = conf_read_to_temp($FORM{"confid"});

	open(my $fh, "+<", qq|./data/serial/$FORM{"confid"}|) or error(get_errmsg("450", $!));
	flock($fh, LOCK_EX);
	seek($fh, 0, 0);
	chomp(my $serial = <$fh>);
	if ($FORM{"SERIAL"} =~ /^([\+\-])(\d+)$/) {
		my $flag = $1;
		my $num = $2;
		my $digit = length($serial);
		$serial = sprintf("%0${digit}d", $flag eq "+" ? $serial + $num : $serial - $num);
	} elsif ($FORM{"SERIAL"} =~ /^(\d+)$/) {
		my $num = $1;
		my $digit = length($num);
		$serial = sprintf("%0${digit}d", $num);
	}
	truncate($fh, 0);
	seek($fh, 0, 0);
	print $fh $serial;
	close($fh);

	printhtml_admin("$p.html",
		"errmsg" => \@errmsg,
		"confid" => $FORM{"confid"},
		"label"  => $conf{"label"},
		"SERIAL" => $FORM{"SERIAL"},
	);
	exit;

}

1;
