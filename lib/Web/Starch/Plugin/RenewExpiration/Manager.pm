package # hide from PAUSE
    Web::Starch::Plugin::RenewExpiration::Manager;

use Types::Standard -types;
use Types::Common::String -types;
use Types::Common::Numeric -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForManager
);

has renew_threshold => (
    is      => 'lazy',
    isa     => PositiveOrZeroInt,
    default => 0,
);

1;
