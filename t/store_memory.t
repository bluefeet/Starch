#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Starch;

Test::Starch->new(
    args => {
        store => { class=>'::Memory' },
    },
)->test_store();

done_testing();
