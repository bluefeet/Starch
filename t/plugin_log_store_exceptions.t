#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Fatal;
use Log::Any::Test;
use Log::Any qw($log);

use Starch;

{
    package Starch::Store::Test::LogStoreExceptions;
    use Moo;
    with 'Starch::Store';
    sub set { die "SET FAIL" }
    sub get { die "GET FAIL" }
    sub remove { die "REMOVE FAIL" }
}

my $log_store = Starch->new_with_plugins(
    ['::LogStoreExceptions'],
    store => { class=>'::Test::LogStoreExceptions' },
)->store();

my $die_store = Starch->new(
    store => { class=>'::Test::LogStoreExceptions' },
)->store();

foreach my $method (qw( set get remove )) {

    $log_store->$method();
    my $uc_method = uc( $method );

    $log->category_contains_ok(
        'Starch::Store::Test::LogStoreExceptions',
        qr{$uc_method FAIL},
        "$method exception logged",
    );
    log_empty_ok();

    like(
        exception { $die_store->$method() },
        qr{$uc_method FAIL},
        "$method exception thrown",
    );

}

done_testing;

# Workaround: https://github.com/dagolden/Log-Any/issues/30
sub log_empty_ok {
    my ($test_msg) = @_;
    $test_msg = 'log is empty' if !defined $test_msg;
    my $msgs = $log->msgs();
    ok( (@$msgs == 0), $test_msg );
    use Data::Dumper;
    diag( Dumper($msgs) ) if @$msgs;
}
