#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Fatal;

use Web::Starch;

{
    package Web::Starch::Store::Test::TimeoutStores;
    use Moo;
    with 'Web::Starch::Store';
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

my $timeout_store = Web::Starch->new_with_plugins(
    ['::TimeoutStores'],
    store => { class=>'::Test::TimeoutStores', timeout=>0.01 },
)->store();

my $normal_store = Web::Starch->new_with_plugins(
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
