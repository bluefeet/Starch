package Web::Starch::Store::Layered;

=head1 NAME

Web::Starch::Store::Layered - Layer multiple stores.

=head1 SYNOPSIS

    my $starch = Web::Starch->new(
        store => {
            class => '::Layered',
            outer => { class=>'::CHI', ... },
            inner => { class=>'::MongoDB', ... },
        },
    );

=head1 DESCRIPTION

This store provides the ability to declare two stores that act
in a layered fashion where all writes are applied to both stores
but all reads are attempted, first, on the L</outer> store, and if that
fails the read is attempted in the L</inner> store.

The most common use-case for this store is for placing a cache in
front of a persistent store.  Typically caches are much faster than
persistent storage engines.

Another use case is for migrating from one store to another.  Your
current store would be set as the outer store, and your new store
would be set as the inner store.  Once sufficient time has passed
you could switch to using just the inner store.

If you'd like to layer more than two stores you can use a layered
stores within layered stores.

=cut

use Types::Standard -types;
use Scalar::Util qw( blessed );

use Moo;
use strictures 1;
use namespace::clean;

with qw(
    Web::Starch::Store
);

=head1 REQUIRED ARGUMENTS

=head2 outer

This is the outer store, the one that tries to handle read requests
first before falling back to the L</inner> store.

Accepts the same value as L<Web::Starch/store>.

=cut

has _outer_arg => (
    is       => 'ro',
    isa      => HasMethods[ 'set', 'get', 'remove' ] | HashRef,
    required => 1,
    init_arg => 'outer',
);

has outer => (
    is       => 'lazy',
    isa      => HasMethods[ 'set', 'get', 'remove' ],
    init_arg => undef,
);
sub _build_outer {
    my ($self) = @_;

    my $outer = $self->_outer_arg();
    return $outer if blessed $outer;

    return $self->factory->new_store( $outer );
}

=head2 inner

This is the inner store, the one that only handles read requests
if the L</outer> store was unable to.

Accepts the same value as L<Web::Starch/store>.

=cut

has _inner_arg => (
    is       => 'ro',
    isa      => HasMethods[ 'set', 'get', 'remove' ] | HashRef,
    required => 1,
    init_arg => 'inner',
);

has inner => (
    is       => 'lazy',
    isa      => HasMethods[ 'set', 'get', 'remove' ],
    init_arg => undef,
);
sub _build_inner {
    my ($self) = @_;

    my $inner = $self->_inner_arg();
    return $inner if blessed $inner;

    return $self->factory->new_store( $inner );
}

=head1 STORE METHODS

See L<Web::Starch::Store> for more documentation about the methods
which all stores implement.

=cut

sub set {
    my $self = shift;
    $self->outer->set( @_ );
    $self->inner->set( @_ );
    return;
}

sub get {
    my $self = shift;
    my $data = $self->outer->get( @_ );
    $data = $self->inner->get( @_ ) if !defined $data;
    return $data;
}

sub remove {
    my $self = shift;
    $self->outer->remove( @_ );
    $self->inner->remove( @_ );
    return;
}

1;
