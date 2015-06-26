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

=head1 OPTIONAL ARGUMENTS

=head2 factory

A L<Web::Starch::Factory> object which is used by stores to
create sub-stores (such as the Layered store's outer and inner
stores).

=cut

has factory => (
    is       => 'ro',
    isa      => InstanceOf[ 'Web::Starch::Factory' ],
    required => 1,
);

=head1 expires

See L<Web::Starch/expires> which this argument defaults to.

=cut

has expires => (
  is       => 'ro',
  isa      => PositiveInt | Undef,
  required => 1,
);

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.

