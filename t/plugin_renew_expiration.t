#!/usr/bin/env perl
use strictures 2;

use Test::More;

use Starch;

subtest disabled => sub{
    my $starch = Starch->new(
        store => { class => '::Memory' },
    );

    my $session = $starch->session();
    $session->data->{foo} = 32;
    my $modified_first = $session->modified();
    $session->save();

    sleep 2;
    $session = $starch->session( $session->id() );
    $session->data();

    $session = $starch->session( $session->id() );
    my $modified_second = $session->modified();

    is( $modified_second, $modified_first, 'session was not auto-saved' );
};

subtest enabled => sub{
    my $starch = Starch->new_with_plugins(
        ['::RenewExpiration'],
        store => { class => '::Memory' },
    );

    my $session = $starch->session();
    $session->data->{foo} = 32;
    my $modified_first = $session->modified();
    $session->save();

    sleep 2;
    $session = $starch->session( $session->id() );
    $session->data();

    $session = $starch->session( $session->id() );
    my $modified_second = $session->modified();

    cmp_ok( $modified_second, '>', $modified_first, 'session was auto-saved' );
};

done_testing;
