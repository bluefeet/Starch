#!/usr/bin/env perl
use strictures 1;

use Test::More;

use Web::Starch;
use Web::Starch::Store::Memory;

my $starch = Web::Starch->new(
    store => { class=>'::Memory' },
);
my $mem = $starch->store();

is( $mem->get('foo'), undef, 'get an unknown key' );

$mem->set( 'foo', {bar=>6} );
isnt( $mem->get('foo'), undef, 'add, then get a known key' );
is( $mem->get('foo')->{bar}, 6, 'known key data value' );

$mem->set( 'foo', {bar=>3} );
is( $mem->get('foo')->{bar}, 3, 'update, then get a known key' );

$mem->remove( 'foo' );
is( $mem->get('foo'), undef, 'get a removed key' );

done_testing();
