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
    is      => 'lazy',
    isa     => NonEmptySimpleStr,
    default => 'session',
);

has cookie_domain => (
    is => 'lazy',
    isa => NonEmptySimpleStr | Undef,
);

has cookie_path => (
    is  => 'lazy',
    isa => NonEmptySimpleStr | Undef,
);

has cookie_secure => (
    is      => 'lazy',
    isa     => Bool,
    default => 1,
);

has cookie_http_only => (
    is      => 'lazy',
    isa     => Bool,
    default => 1,
);

1;
