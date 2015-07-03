package Web::Starch::Store;

=head1 NAME

Web::Starch::Store - Role for session stores.

=head1 DESCRIPTION

This role defines an interfaces for session store classes.  Session store
classes are meant to be thin wrappers around the store implementations
(such as DBI, CHI, etc).

See L<Web::Starch::Manual/STORES> for instructions on using stores and a
list of available session stores.

See L<Web::Starch::Manual::Extending/STORES> for instructions on writing
your own stores.

This role adds support for method proxies to consuming classes as
described in L<Web::Starch::Manual/METHOD PROXIES>.

=cut

use Types::Standard -types;
use Types::Common::Numeric -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Role::Log
    Web::Starch::Role::MethodProxy
);

requires qw(
    set
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

=head1 METHODS

All store classes must implement the C<set>, C<get>, and C<remove> methods.

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.

