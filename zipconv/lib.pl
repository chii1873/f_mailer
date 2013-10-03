sub _init_db {

    my $dbh = DBI->connect("dbi:Pg:dbname=zip", "postgres", "",
     { RaiseError => 0, AutoCommit => 0 });
    error("データベースの接続ができませんでした。: $DBI::errstr")
     if $DBI::errstr;
    return $dbh;

}

sub decoding {

    my($q) = @_;
    my %FORM;
    foreach my $name($q->param()) {
        foreach my $each($q->param($name)) {
#            jcode::convert(\$each,'sjis');
            if (defined($FORM{$name})) {
                $FORM{$name} = join('|||', $FORM{$name}, $each);
            } else {
                $FORM{$name} = $each;
            }
        }
    }
    %FORM;
}

sub error {

    print "Pragma: no-cache\n";
    print "Cache-Control: no-cache\n";
    print "Expires: ", get_datetime_for_cookie(10), "\n";
    printhtml("tmpl/_error.html", errmsg=> join("", map { "<li>$_\n" } @_));
    exit;

}

sub error_close {

    print "Pragma: no-cache\n";
    print "Cache-Control: no-cache\n";
    print "Expires: ", get_datetime_for_cookie(10), "\n";
    printhtml("tmpl/_error_close.html", errmsg=> join("", map { "<li>$_\n" } @_));
    exit;

}

sub get_datetime_for_cookie {

    my($time) = @_;
    my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime(time + $time);
    sprintf("%s, %02d-%s-%04d %02d:%02d:%02d GMT",
     (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday],
     $mday, (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon],
     $year+1900, $hour, $min, $sec);

}

sub printhtml {

    my($filename, @tr) = @_;
    $filename or error("printhtml: 使用するhtmlファイルを指定してください。");

    my $htmlstr;
    foreach my $file(split(/\s+/, $filename)) {
        open(R, $file)
         or die("printhtml: $file が開けませんでした。 $!");
        $htmlstr .= join("", <R>);
        close(R);
    }
    my $hf = sub {
        my $f = shift;
        open(R, "data/tmpl/__$f.html")
         or error("printhtml: data/tmpl/__$f.html が開けませんでした。 $!");
        return join("", <R>);
    };
    $htmlstr =~ s/<!--\s*((?:head|foot)er)\s*-->/&{$hf}($1)/ieg;
    $htmlstr =~ s|##version##|$CONF{version}.($ENV{SERVER_NAME} =~ /t\./ ? " [Test Mode]" : "")|ieg;
#    jcode::convert(\$htmlstr, 'euc', 'sjis');
    while (my $pattern = shift(@tr)) {
        my $replace = shift(@tr);
#        jcode::convert(\$pattern, 'euc', 'sjis');
#        jcode::convert(\$replace, 'euc', 'sjis');
        $htmlstr =~ s|##$pattern##|$replace|g;
#        eval "\$htmlstr =~ s|##$pattern##|$replace|g;";
        error($@,$pattern,$replace) if $@;
    }
#    jcode::convert(\$htmlstr, 'sjis', 'euc');
    print "Content-type: text/html;charset=utf-8\n\n$htmlstr";

}

sub sql_selectall {

    my($dbh, $sql) = @_;
    my $sql_euc = $sql;
#    jcode::convert(\$sql_euc,'euc','sjis');

    (my $sql_euc_log = $sql_euc) =~ s/\s*\r?\n\s*/ /g;

    my $sth = $dbh->prepare($sql_euc);
    if ($dbh->errstr) {
        error($dbh->errstr,$sql);
    }
    $sth->execute;
    if ($dbh->errstr) {
        error($dbh->errstr,$sql);
    }
    my @hash_ref;
    while (my $hash_ref = $sth->fetchrow_hashref) {
        push(@hash_ref, $hash_ref);
    }

    return wantarray ? @hash_ref : \@hash_ref;

}

sub zen_to_han {

    my($str, %mode) = @_;
    $str = Unicode::Japanese->new( $str )->z2h->get;
    $str =~ tr/\D//d if $mode{del};
    $str;
}

1;
