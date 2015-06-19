package Web::Starch::Store::Memory;

=head1 NAME

Web::Starch::Store::Memory - In-memory session store.

=head1 DESCRIPTION

This store provides an in-memory store using a Perl Hash to store the
data.  This store is mostly here as a proof of concept and for writing
tests against.

=cut

use Types::Standard -types;
use Types::Common::Numeric -types;

use Moo;
use strictures 1;
use namespace::clean;

with qw(
  Web::Starch::Store
);

=head1 ARGUMENTS

=head2 expires

The number of seconds to expire data in.

Defaults to C<undef>, which means no expiration.

=cut

has expires => (
  is  => 'ro',
  isa => PositiveInt,
);

=head2 global

By default the in-memory storage will not be shared by instances of
this class.  If you turn on the global option then all other instances
in the same process which also have global set will share the same storage.

=cut

has global => (
  is  => 'ro',
  isa => Bool,
);

my $global_memory = {};

=head1 ATTRIBUTES

=head2 memory

This is the hash ref which is used for storing sessions.

=cut

has memory => (
  is  => 'lazy',
  isa => HashRef,
);
sub _build_memory {
  my ($self) = @_;
  return $global_memory if $self->global();
  return {};
}

=head1 STORE METHODS

See L<Web::Starch::Store> for more documentation about the methods
which all stores implement.

=cut

sub set {
  my ($self, $key, $value) = @_;

  $self->memory->{$key} = {
    value   => $value,
    expires => $self->abs_expires(),
  };

  return;
}

sub get {
  my ($self, $key) = @_;
  my $data = $self->memory->{$key};
  return undef if !$data;
  return undef if $data->{expires} and $data->{expires} <= time();
  return $data->{value};
}

sub remove {
  my ($self, $key) = @_;
  delete( $self->memory->{$key} );
  return;
}

=head1 OTHER METHODS

=head2 abs_expires

Returns C<time()> plus the value of L</expires>, if L</expires> is set.
If it is not set then C<undef> will be returned.

=cut

sub abs_expires {
  my ($self) = @_;
  my $expires = $self->expires();
  return undef if !defined $expires;
  return time() + $expires;
}

1;
