#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Fatal;

{
    package Web::Starch::Test::Role::MethodProxy;
    use Moo;
    with 'Web::Starch::Role::MethodProxy';
    around BUILDARGS => sub{
        my $orig = shift;
        my $class = shift;
        my $args = $class->$orig( @_ );
        return { build_args => $args };
    };
    has build_args => ( is=>'ro' );
}

{
    package Web::Starch::Test::CallMethodProxy;
    use Moo;
    sub foo { shift; return @_ }
}

my $class = 'Web::Starch::Test::Role::MethodProxy';
my $package = 'Web::Starch::Test::CallMethodProxy';
my $method = 'foo';

subtest is_method_proxy => sub{
    ok(
        $class->is_method_proxy( ['&proxy', 'foo'] ),
        'valid method proxy',
    );

    ok(
        (!$class->is_method_proxy( ['&proxyy', 'foo'] )),
        'invalid method proxy',
    );
};

subtest call_method_proxy => sub{
    like(
        exception { $class->call_method_proxy() },
        qr{not an array ref},
        'no arguments errored',
    );

    like(
        exception { $class->call_method_proxy([]) },
        qr{"&proxy"},
        'empty array ref errored',
    );

    like(
        exception { $class->call_method_proxy(['foobar']) },
        qr{"&proxy"},
        'array ref without "&proxy" at the start errored',
    );

    like(
        exception { $class->call_method_proxy(['&proxy']) },
        qr{package is undefined},
        'missing package errored',
    );

    like(
        exception { $class->call_method_proxy(['&proxy', $package]) },
        qr{method is undefined},
        'missing method errored',
    );

    like(
        exception { $class->call_method_proxy(['&proxy', '    ', $method]) },
        qr{not a valid package},
        'invalid package errored',
    );

    like(
        exception { $class->call_method_proxy(['&proxy', "Unknown::$package", $method]) },
        qr{Can't locate},
        'non-existing package errored',
    );

    like(
        exception { $class->call_method_proxy(['&proxy', $package, "unknown_$method"]) },
        qr{does not support the .* method},
        'non-existing method errored',
    );

    is(
        exception { $class->call_method_proxy(['&proxy', $package, $method]) },
        undef,
        'proxy did not error',
    );

    is_deeply(
        [ $class->call_method_proxy([ '&proxy', $package, $method, 'bar' ]) ],
        [ 'bar' ],
        'proxy worked',
    );
};

my $complex_data_in = {
    foo => 'FOO',
    bar => [ '&proxy', $package, $method, 'BAR' ],
    ary => [
        'one',
        [ '&proxy', $package, $method, 'two' ],
        'three',
    ],
    hsh => {
        this => 'that',
        those => [ '&proxy', $package, $method, 'these' ],
    },
};

my $complex_data_out = {
    foo => 'FOO',
    bar => 'BAR',
    ary => ['one', 'two', 'three'],
    hsh => { this=>'that', those=>'these' },
};

subtest apply_method_proxies => sub{
    my $data = $class->apply_method_proxies( $complex_data_in );

    is_deeply(
        $data,
        $complex_data_out,
        'worked',
    );
};

subtest BUILDARGS => sub{
    is_deeply(
        $class->new( $complex_data_in )->build_args(),
        $complex_data_out,
        'worked',
    );
};

done_testing;
