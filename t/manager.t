#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Web::Starch;

Test::Web::Starch->new->test_manager();

done_testing;
