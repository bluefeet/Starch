package Web::Starch::Store;

=head1 NAME

Web::Starch::Store - Role for session stores.

=head1 DESCRIPTION

This role defines an interfaces for session store classes.  Session store
classes are meant to be thin wrappers around the store implementations
(such as DBI, CHI, etc).

This role consumes the L<Web::Starch::Component> role.

=head1 CORE STORES

These stores are included with the C<Web-Starch> distribution.

=over

=item *

L<Web::Starch::Store::Memory>

=item *

L<Web::Starch::Store::Layered>

=back

=head1 EXTERNAL STORES

These stores are distributed separately on CPAN.

=over

=item *

L<Web::Starch::Store::CHI>

=back

More third-party plugins can be found on
L<meta::cpan|https://metacpan.org/search?q=Web%3A%3AStarch%3A%3APlugin>.

=head1 REQUIRED METHODS

Store classes must implement these three methods.

=head2 set

    $store->set( $key, \%data, $expires );

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
use Types::Common::Numeric -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Component
);

requires qw(
    get
    remove
);

around set => sub{
    my $orig = shift;
    my $self = shift;

    my $expires = $self->expires();
    return $self->$orig( @_ ) if !defined $expires;

    my ($key, $data) = @_;
    return $self->$orig( $key, $data, $expires );
};

=head1 REQUIRED ARGUMENTS

=head2 factory

A L<Web::Starch::Factory> object which is used by stores to
create sub-stores (such as the Layered store's outer and inner
stores).  This is automatically set when the stores are built by
L<Web::Starch::Factory>.

=cut

has factory => (
    is       => 'ro',
    isa      => InstanceOf[ 'Web::Starch::Factory' ],
    required => 1,
);

=head1 OPTIONAL ARGUMENTS

=head2 expires

Setting this to a positive integer tells the store to override whatever
expiration the session specifies.  This is useful for when you're using
layered stores where the outer store is a cache and you want the cache
to hold on to the session data for less time than the inner store.

Setting this to zero tells the store to not specify any particular expiration.
This is useful for backends that use LRU for expiration, such as Memcached.

=cut

has expires => (
  is  => 'ro',
  isa => PositiveOrZeroInt,
);

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.

