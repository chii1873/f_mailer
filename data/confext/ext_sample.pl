#
# FORM MAILER v0.6 拡張設定ファイル
# (c)1997-2008 Perl Script Laboratory All rights reserved.
#
# ext_sample.pl
#
# このファイルはプログラムによって自動生成されました。
# 生成日時: 2006-10-01 02:26:11

#package ext;

sub ext_sub0 {

}

### (11)付加的に実行したいコード1
### サブルーチン内でグローバル変数を使用できます(パッケージ名に注意)
### エラーメッセージのリストを戻り値に指定するとエラーページに遷移します。
### このサブルーチンは入力値チェックの一番最後に実行されます。
sub ext_sub {

    my @errmsg;
    my %FORM = %main::FORM;

    return @errmsg;

}

### (12)付加的に実行したいコード2
### サブルーチン内でグローバル変数を使用できます(パッケージ名に注意)
### エラーメッセージのリストを戻り値に指定するとエラーページに遷移します。
### このサブルーチンはメール送信の直前に実行されます。
sub ext_sub2 {

    my @errmsg;
    my %FORM = %main::FORM;

    return @errmsg;

}

1;
