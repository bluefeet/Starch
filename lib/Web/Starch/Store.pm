package Web::Starch::Store;

=head1 NAME

Web::Starch::Store - Role for session stores.

=head1 DESCRIPTION

This role defines an interfaces for session store classes.  Session store
classes are meant to be thin wrappers around the store implementations
(such as DBI, CHI, etc).

See L<Web::Starch::Manual/STORES> for instructions on using stores and a
list of available session stores.

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

Sets the data for the key.  The C<$expires> value will always be set and
will be either C<0> or a postive integer representing the number of seconds
in the future that this session data should be expired.  If C<0> then the
store may expire the data whenever it chooses.

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
    Web::Starch::Role::Log
);

requires qw(
    get
    remove
);

around set => sub{
    my $orig = shift;
    my $self = shift;

    my $max_expires = $self->max_expires();
    return $self->$orig( @_ ) if !defined $max_expires;

    my ($key, $data, $expires) = @_;
    return $self->$orig( @_ ) if $expires <= $max_expires;

    return $self->$orig( $key, $data, $max_expires );
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

=head2 max_expires

Set the per-store maximum expires wich will override the session's expires
if the session's expires is larger.

=cut

has max_expires => (
  is  => 'ro',
  isa => PositiveOrZeroInt,
);

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.

