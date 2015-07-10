#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Web::Starch;

Test::Web::Starch->new(
    args => {
        store => { class=>'::Memory' },
    },
)->test_store();

done_testing();
