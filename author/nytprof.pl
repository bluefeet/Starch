#!/usr/bin/env perl
use strictures 2;

my $iters = 10_000;

use Devel::NYTProf;

use Starch;

my $starch = Starch->new(
    store => { class=>'::Memory' },
);
#my $starch = Starch->new_with_plugins(
#    ['::Sereal'],
#    store => { class=>'::Memory' },
#);

foreach (1..$iters) {
    my $session = $starch->session();

    $session->data->{foo} = 32;

    if ($session->data->{bar}) { ... }

    $session->save();

    $session = $starch->session( $session->id() );

    if ($session->data->{bar}) { ... }

    $session->save();

    $session = $starch->session( $session->id() );
}
