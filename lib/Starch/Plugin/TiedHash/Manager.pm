package Starch::Plugin::TiedHash::Manager;
our $VERSION = '0.14';

use Types::Common::String -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Starch::Plugin::ForManager';

has tied_hash_class => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    required => 1,
);

1;
