package Web::Starch::Plugin::CookieArgs::Manager;

use Types::Standard -types;
use Types::Common::String -types;
use Types::Common::Numeric -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForManager
);

has cookie_name => (
    is  => 'lazy',
    isa => NonEmptySimpleStr,
);
sub _build_cookie_name {
    return 'session';
}

has cookie_domain => (
    is => 'lazy',
    isa => NonEmptySimpleStr | Undef,
);
sub _build_cookie_domain {
    return undef;
}

has cookie_path => (
    is  => 'lazy',
    isa => NonEmptySimpleStr,
);
sub _build_cookie_path {
    return '/';
}

has cookie_secure => (
    is  => 'lazy',
    isa => Bool,
);
sub _build_cookie_secure {
    return 1;
}

has cookie_http_only => (
    is  => 'lazy',
    isa => Bool,
);
sub _build_cookie_http_only {
    return 1;
}

1;
