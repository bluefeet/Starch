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

around is_data_diff => sub{
    my ($orig, $self, $old, $new) = @_;

    # The default serializer, Storable, includes tied information with the serialized output.
    # This causes this comparison to always find a difference since original_data is never tied
    # and data is always tied when using this plugin. Avoid all this by shallow cloning both.
    return $self->$orig(
        { %$old },
        { %$new },
    );
};

1;
