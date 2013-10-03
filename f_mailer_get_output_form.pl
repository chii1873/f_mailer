# ---------------------------------------------------------------
#  - システム名    フォームデコード+メール送信 (FORM MAILER)
#  - バージョン    0.62
#  - 公開年月日    2007/10/9
#  - スクリプト名  f_mailer_lib_admin.pl
#  - 著作権表示    (c)1997-2007 Perl Script Laboratory
#  - 連  絡  先    http://www.psl.ne.jp/bbpro/
#                  https://awawa.jp/psl/lab/pslform.html
# ---------------------------------------------------------------
# ご利用にあたっての注意
#   ※このシステムはフリーウエアです。
#   ※このシステムは、「利用規約」をお読みの上ご利用ください。
#     http://www.psl.ne.jp/lab/copyright.html
# ---------------------------------------------------------------
use strict;
use vars qw(%CONF %FORM %alt $q);
use HTML::SimpleParse;

sub get_output_form {

    my($phase, $content, %d) = @_;   ### 差し込みデータ
    {
        my %d_;
        while (my($k, $v) = each %d) {
            $k = Unicode::Japanese->new($k, "utf8")->getu;
            $v = Unicode::Japanese->new($v, "utf8")->getu;
            $d_{$k} = $v;
        }
        %d = %d_;
    }

    my $p = new HTML::SimpleParse($content);
    my %is_formtag = map { $_ => 1 } qw(input select textarea);
    my $output;   ### 出力用htmlデータ
    my $select_flag = 0; # select/textareaの閉じ対応チェック用
    my $option_flag = 0;
    my $textarea_flag = 0;
    my $now_name; # optionタグのname保持用
    my $option_stack; # optionタグのvalue用コンテナ

    foreach ($p->tree) {
        my %c = %$_;
        @c{qw(tagname content_)} = split(/\s+/, $c{content}, 2);
        $c{tagname} = lc($c{tagname});
        if ($c{type} eq "starttag") {
            my %h = $p->parse_args( $c{content_} );
            { my %h_; for (keys %h) { $h_{lc($_)} = $h{$_} }; %h = %h_ }
            if ($c{tagname} eq "input") {
                $h{type} = lc($h{type});
                if ($h{type} eq "" or $h{type} eq "text" or $h{type} eq "password") {
                    $h{value} = $d{$h{name}};
                } elsif ($h{type} eq "checkbox" or $h{type} eq "radio") {
                    if (exists $d{"$h{name}\0$h{value}"}) {
                        $h{checked} = q|checked="checked"|;
                    } else {
                        delete $h{checked} if exists $h{checked};
                    }
                } elsif ($h{type} eq "image") {
                    $h{src} = $CONF{"${phase}_TMPL_BASE_URL"}.$h{src}
                     unless $h{src} =~ m#^(?:/|https*)#i;
                } elsif ($h{type} eq "hidden") {
                    unless (exists $h{value} and $d{$h{name}} eq "") {
                        $h{value} = $d{$h{name}};
                    }
                }
                $output .= get_output_form_remake_tag($c{tagname}, %h);
            } elsif ($c{tagname} eq "select") {
                $select_flag = 1;
                $now_name = $h{name};
                $output .= "<$c{content}>";
            } elsif ($c{tagname} eq "textarea") {
                $textarea_flag = 1;
                $now_name = $h{name};
                $output .= "<$c{content}>";
            } elsif ($c{tagname} eq "option") {
                if ($option_stack) {
                    %h = (%h, %$option_stack);
                    $option_stack = undef;
                    $output .= get_output_form_set_option_tag($now_name, \%h, \%d);
                }
                if (exists $h{value}) {
                    $output .= get_output_form_set_option_tag($now_name, \%h, \%d);
                } else {
                    $option_stack = {%h};
                }
            } elsif ($c{tagname} eq "form" and $h{action} =~ /f_mailer\.cgi$/) {
                $output .= get_output_form_remake_tag($c{tagname}, %h, action=>"f_mailer.cgi");
            } elsif ($c{tagname} eq "a" or $c{tagname} eq "link") {
                $h{href} = $CONF{"${phase}_TMPL_BASE_URL"}.$h{href}
                 unless $h{href} =~ m{^(?:/|https*|javascript|#)}i;
                $output .= get_output_form_remake_tag($c{tagname}, %h);
            } elsif ($c{tagname} eq "img" or $c{tagname} eq "script") {
                $h{src} = $CONF{"${phase}_TMPL_BASE_URL"}.$h{src}
                 if defined $h{src} and $h{src} !~ m#^(?:/|https*)#i;
                $output .= get_output_form_remake_tag($c{tagname}, %h);
            } else {
                $output .= "<$c{content}>"; # returns as-is
            }

        } elsif ($c{type} eq "text") {
            if ($select_flag) {
                if ($option_stack) {
                    my ($content, $space) = $c{content} =~ /^(.*)(\s*)$/;
                    $option_stack->{value} = $content;
#                    $output .= get_output_form_set_option_tag($now_name, $option_stack, \%d);
#                    $output .= $space;
                } else {
                    $output .= $c{content};
                }
            } elsif ($textarea_flag) {
                1;  # skip -- endtagで処理
            } else {
                $output .= $c{content};
            }
        } elsif ($c{type} eq "endtag") {
            if ($c{tagname} eq "/textarea") {
                $output .= $d{$now_name};
                $textarea_flag = 0;
            } elsif ($c{tagname} eq "/option" or $c{tagname} eq "/select") {
                if ($option_stack) {
                    my %h = %$option_stack;
                    $option_stack = undef;
                    $output .= get_output_form_set_option_tag($now_name, \%h, \%d);
                }
                $select_flag = 0;
            }
            $output .= qq|<$c{tagname}>|;
        } else {
            $output .= "<$c{content}>";
        }
    }

    return $output;

}

sub get_output_form_remake_tag {

    my($tagname, %h) = @_;

    return "<$tagname "
     . join(" ", (map { qq|$_="|.scalar($h{$_}=~s/"/&quot;/g,$h{$_}).qq|"| }
      sort grep { $_ ne "/" } keys %h), $tagname =~ /(?:input|img|link)$/ ? "/" : ())
     . ">";

}

sub get_output_form_set_option_tag {

    my($now_name, $h, $d) = @_;
    my %h = %$h;
    my %d = %$d;

    if (exists $d{"$now_name\0$h{value}"}) {
        $h{selected} = q|selected="selected"|;
    } else {
        delete $h{selected} if exists $h{selected};
    }
    return get_output_form_remake_tag("option", %h);

}

1;
