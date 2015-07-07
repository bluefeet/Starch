package Web::Starch::Store::Layered;

=head1 NAME

Web::Starch::Store::Layered - Layer multiple stores.

=head1 SYNOPSIS

    my $starch = Web::Starch->new(
        expires => 2 * 60 * 60, # 2 hours
        store => {
            class => '::Layered',
            outer => {
                class=>'::CHI',
                max_expires => 10 * 60, # 10 minutes
                ...,
            },
            inner => {
                class=>'::MongoDB',
                ...,
            },
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
new store would be set as the inner store, and your old store
would be set as the outer store.  Once sufficient time has passed,
and the new store has been populdated, you could switch to using
just the new store.

If you'd like to layer more than two stores you can use layered
stores within layered stores.

=cut

use Types::Standard -types;
use Scalar::Util qw( blessed );

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Store
);

sub BUILD {
    my ($self) = @_;

    # Load these up as early as possible.
    $self->outer();
    $self->inner();

    return;
}

=head1 REQUIRED ARGUMENTS

=head2 outer

This is the outer store, the one that tries to handle read requests
first before falling back to the L</inner> store.

Accepts the same value as L<Web::Starch/store>.

=cut

has _outer_arg => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
    init_arg => 'outer',
);

has outer => (
    is       => 'lazy',
    isa      => ConsumerOf[ 'Web::Starch::Store' ],
    init_arg => undef,
);
sub _build_outer {
    my ($self) = @_;
    my $store = $self->_outer_arg();
    return $self->new_sub_store( %$store );
}

=head2 inner

This is the inner store, the one that only handles read requests
if the L</outer> store was unable to.

Accepts the same value as L<Web::Starch/store>.

=cut

has _inner_arg => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
    init_arg => 'inner',
);

has inner => (
    is       => 'lazy',
    isa      => ConsumerOf[ 'Web::Starch::Store' ],
    init_arg => undef,
);
sub _build_inner {
    my ($self) = @_;
    my $store = $self->_inner_arg();
    return $self->new_sub_store( %$store );
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
    my ($self, $key) = @_;

    my $data = $self->outer->get( $key );
    return $data if $data;

    $data = $self->inner->get( $key );
    return undef if !$data;

    # Now we got the data from the inner store but not the outer store.
    # Let's set it on the outer store so that we can retrieve it from
    # there next time.

    my $expires = $data->{ $self->manager->expires_session_key() };
    # The session data is incomplete if it doesn't contain expires data.
    # Maybe we should log this as an error or warning?
    return $data if !defined $expires;

    # Make sure we take into account max_expires.
    $expires = $self->calculate_expires( $expires );

    $self->outer->set( $key, $data, $expires );

    return $data;
}

sub remove {
    my $self = shift;
    $self->outer->remove( @_ );
    $self->inner->remove( @_ );
    return;
}

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.

