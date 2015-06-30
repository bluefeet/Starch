#!/usr/bin/env perl
use strictures 2;

use Test::More;

use Web::Starch;

my $id = 123;

{
    my $starch = Web::Starch->new(
        store => { class => '::Memory', global => 1 },
    );
    my $session = $starch->session( $id );
    $session->data->{foo} = 456;
    $session->save();
}

subtest disabled => sub{
    my $starch = Web::Starch->new(
        store => { class => '::Memory', global => 1 },
    );

    my $session = $starch->session( $id );
    ok( (!$session->is_loaded()), 'session is not loaded' );
    is( $session->data->{foo}, 456, 'data looks good' );
    ok( $session->is_loaded(), 'session is now loaded' );
};

subtest enabled => sub{
    my $starch = Web::Starch->new_with_plugins(
        ['::AlwaysLoad'],
        store => { class => '::Memory', global => 1 },
    );

    my $session = $starch->session( $id );
    ok( $session->is_loaded(), 'session is loaded' );
    is( $session->data->{foo}, 456, 'data looks good' );
};

done_testing;
