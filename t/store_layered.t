#!/usr/bin/env perl
use strictures 2;

use Test::More;

use Web::Starch;

subtest basics => sub{
    my $starch = Web::Starch->new(
        store => {
            class => '::Layered',
            outer => { class=>'::Memory' },
            inner => { class=>'::Memory' },
        },
    );

    my $layered = $starch->store();
    my $outer = $layered->outer();
    my $inner = $layered->inner();

    $layered->set( foo => 32 );
    is( $layered->get('foo'), 32, 'layered get' );
    is( $outer->get('foo'), 32, 'outer get' );
    is( $inner->get('foo'), 32, 'inner get' );

    $layered->set( foo => 59 );
    $outer->remove('foo');
    is( $layered->get('foo'), 59, 'layered get (no outer)' );
    is( $outer->get('foo'), undef, 'outer get (no outer)' );
    is( $inner->get('foo'), 59, 'inner get (no outer)' );

    $layered->set( foo => 16 );
    $inner->remove('foo');
    is( $layered->get('foo'), 16, 'layered get (no inner)' );
    is( $outer->get('foo'), 16, 'outer get (no inner)' );
    is( $inner->get('foo'), undef, 'inner get (no inner)' );
};

subtest max_expires => sub{
    my $starch = Web::Starch->new(
        store => {
            class => '::Layered',
            outer => { class=>'::Memory' },
            inner => { class=>'::Memory', max_expires=>23 },
        },
        expires => 12,
    );
    is( $starch->store->max_expires(), undef, 'the layered store got undef max_expires' );
    is( $starch->store->outer->max_expires(), undef, 'the outer store got undef max_expires' );
    is( $starch->store->inner->max_expires(), 23, 'the inner store got the explicit max_expires' );

    $starch = Web::Starch->new(
        store => {
            class => '::Layered',
            max_expires => 45,
            outer => { class=>'::Memory' },
            inner => { class=>'::Memory', max_expires=>23 },
        },
        expires => 12,
    );
    is( $starch->store->max_expires(), 45, 'the layered store got the explicit max_expires' );
    is( $starch->store->outer->max_expires(), 45, 'the outer store got the layered max_expires' );
    is( $starch->store->inner->max_expires(), 23, 'the inner store got the explicit max_expires' );
};

done_testing();
