#!/usr/bin/env perl
use strictures 1;

use Test::More;

use Web::Starch;

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

done_testing();
