#!/usr/bin/env perl
use strictures 2;

use Test::More;

use Starch;

subtest 'without auto save' => sub{
    my $starch = Starch->new(
        store => { class => '::Memory' },
    );

    my $session = $starch->session();
    $session->data->{foo} = 54;
    $session = $starch->session( $session->id() );
    is( $session->data->{foo}, undef, 'did not auto save' );
};

subtest 'with auto save' => sub{
    my $starch = Starch->new_with_plugins(
        ['::AutoSave'],
        store => { class => '::Memory' },
    );

    my $session = $starch->session();
    $session->data->{foo} = 76;
    $session = $starch->session( $session->id() );
    is( $session->data->{foo}, 76, 'did auto save' );
};

done_testing;
