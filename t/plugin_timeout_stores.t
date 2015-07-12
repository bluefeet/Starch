#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Fatal;
use Test::Starch;
use Starch;

Test::Starch->new(
    plugins => ['::TimeoutStores'],
)->test();

if (!eval('use 5.010_000; 1')) {
    plan skip_all => 'This test will only function with Perl 5.10 or newer.';
}

{
    package Starch::Store::Test::TimeoutStores;
    use Moo;
    with 'Starch::Store';
    sub set { _sleep_one() }
    sub get { _sleep_one() }
    sub remove { _sleep_one() }
    sub _sleep_one {
        my $start = time();
        while (1) {
            last if time() > $start + 1;
        }
        return;
    }
}

my $timeout_store = Starch->new_with_plugins(
    ['::TimeoutStores'],
    store => { class=>'::Test::TimeoutStores', timeout=>0.01 },
)->store();

my $normal_store = Starch->new_with_plugins(
    ['::TimeoutStores'],
    store => { class=>'::Test::TimeoutStores' },
)->store();

foreach my $method (qw( set get remove )) {
    is(
        exception { $normal_store->$method() },
        undef,
        "no timeout when calling $method",
    );

    like(
        exception { $timeout_store->$method() },
        qr{timeout},
        "timeout when calling $method",
    );
}

done_testing;
