#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Fatal;

use Web::Starch::Util qw(
    load_prefixed_module
    call_method_proxy
    is_method_proxy
);

subtest load_prefixed_module => sub{
    my $prefix = 'Web::Starch';
    my $suffix = '::Test::LoadPrefixedModule';
    my $package = $prefix . $suffix;
    like(
        exception { load_prefixed_module( $prefix, $package ) },
        qr{Can't locate},
        'load_prefixed_module failed on non-existing module',
    );

    eval "package $package; use Moo";

    is(
        load_prefixed_module( $prefix, $package ),
        'Web::Starch::Test::LoadPrefixedModule',
        'load_prefixed_module on absolute package name',
    );

    is(
        load_prefixed_module( $prefix, $suffix ),
        'Web::Starch::Test::LoadPrefixedModule',
        'load_prefixed_module on relative package name',
    );
};

subtest is_method_proxy => sub{
    ok(
        is_method_proxy( ['&proxy', 'foo'] ),
        'valid method proxy',
    );

    ok(
        (!is_method_proxy( ['&proxyy', 'foo'] )),
        'invalid method proxy',
    );
};

subtest call_method_proxy => sub{
    my $package = 'Web::Starch::Test::CallMethodProxy';
    my $method = 'foo';

    like(
        exception { call_method_proxy() },
        qr{not an array ref},
        'no arguments errored',
    );

    like(
        exception { call_method_proxy([]) },
        qr{"&proxy"},
        'empty array ref errored',
    );

    like(
        exception { call_method_proxy(['foobar']) },
        qr{"&proxy"},
        'array ref without "&proxy" at the start errored',
    );

    like(
        exception { call_method_proxy(['&proxy']) },
        qr{package is undefined},
        'missing package errored',
    );

    like(
        exception { call_method_proxy(['&proxy', $package]) },
        qr{method is undefined},
        'missing method errored',
    );

    like(
        exception { call_method_proxy(['&proxy', '    ', $method]) },
        qr{not a valid package},
        'invalid package errored',
    );

    like(
        exception { call_method_proxy(['&proxy', $package, $method]) },
        qr{Can't locate},
        'non-existing package errored',
    );

    eval "
        package $package;
        use Moo;
        sub foo { shift; return \@_ }
    ";

    is(
        exception { call_method_proxy(['&proxy', $package, $method]) },
        undef,
        'proxy did not error',
    );

    is_deeply(
        [ call_method_proxy([ '&proxy', $package, $method, 'bar' ]) ],
        [ 'bar' ],
        'proxy worked',
    );
};

done_testing;
