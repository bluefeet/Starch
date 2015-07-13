#!/usr/bin/env perl
use strictures 2;

use Test::More;

use Starch;

subtest 'without auto save' => sub{
    my $starch = Starch->new(
        store => { class => '::Memory' },
    );

    my $state = $starch->state();
    $state->data->{foo} = 54;
    $state = $starch->state( $state->id() );
    is( $state->data->{foo}, undef, 'did not auto save' );
};

subtest 'with auto save' => sub{
    my $starch = Starch->new(
        plugins => ['::AutoSave'],
        store => { class => '::Memory' },
    );

    my $state = $starch->state();
    $state->data->{foo} = 76;
    $state = $starch->state( $state->id() );
    is( $state->data->{foo}, 76, 'did auto save' );
};

done_testing;
