#!/usr/bin/env perl
use strictures 2;

use Test::More;

use Web::Starch;

subtest basics => sub{
    my $starch = Web::Starch->new( store=>{class=>'::Memory'} );
    my $mem = $starch->store();

    is( $mem->get('foo'), undef, 'get an unknown key' );

    $mem->set( 'foo', {bar=>6} );
    isnt( $mem->get('foo'), undef, 'add, then get a known key' );
    is( $mem->get('foo')->{bar}, 6, 'known key data value' );

    $mem->set( 'foo', {bar=>3} );
    is( $mem->get('foo')->{bar}, 3, 'update, then get a known key' );

    $mem->remove( 'foo' );
    is( $mem->get('foo'), undef, 'get a removed key' );
};

subtest expires => sub{
    my $starch = Web::Starch->new(
        store=>{ class=>'::Memory' },
        expires => 89,
    );
    is( $starch->store->expires(), 89, 'store expires defaulted to the global expires' );

    $starch = Web::Starch->new(
        store=>{ class=>'::Memory', expires=>67 },
        expires => 89,
    );
    is( $starch->store->expires(), 67, 'store expires explicitly set' );
};

done_testing();
