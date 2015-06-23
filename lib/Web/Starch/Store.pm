package Web::Starch::Store;

=head1 NAME

Web::Starch::Store - Role for session stores.

=head1 DESCRIPTION

This role defines an interfaces for session store classes.  Session store
classes are meant to be thin wrappers around the store implementations
(such as DBI, CHI, etc).

This role consumes the L<Web::Starch::Component> role.

=head1 REQUIRED METHODS

Store classes must implement these three methods.

=head2 set

    $store->set( $key, \%data );

Sets the data for the key.

=head2 get

    my $data = $store->get( $key );

Returns the data for the given key.  If the data was not found then
C<undef> is returned.

=head2 remove

    $store->remove( $key );

Deletes the data for the key.  If the data does not exist then this is just
a no-op.

=cut

use Types::Standard -types;

use Moo::Role;
use strictures 1;
use namespace::clean;

with qw(
    Web::Starch::Component
);

requires qw(
    set
    get
    remove
);

has factory => (
    is  => 'lazy',
    isa => HasMethods[ 'store_class' ],
);
sub _build_factory {
    return Web::Starch::Factory->new();
}

1;
