#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Fatal;

{
    package Web::Starch::Test::Role::LoadPrefixedModule;
    use Moo;
    with 'Web::Starch::Role::LoadPrefixedModule';
}

my $class = 'Web::Starch::Test::Role::LoadPrefixedModule';

my $prefix = 'Web::Starch';
my $suffix = '::Test::LoadPrefixedModule';
my $package = $prefix . $suffix;
like(
    exception { $class->load_prefixed_module( $prefix, $package ) },
    qr{Can't locate},
    'load_prefixed_module failed on non-existing module',
);

eval "package $package; use Moo";

is(
    $class->load_prefixed_module( $prefix, $package ),
    'Web::Starch::Test::LoadPrefixedModule',
    'load_prefixed_module on absolute package name',
);

is(
    $class->load_prefixed_module( $prefix, $suffix ),
    'Web::Starch::Test::LoadPrefixedModule',
    'load_prefixed_module on relative package name',
);

done_testing;
