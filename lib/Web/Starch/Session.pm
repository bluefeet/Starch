package Web::Starch::Session;

=head1 NAME

Web::Starch::Session - The starch session object.

=head1 SYNOPSIS

  my $session = $starch->session();
  $session->data->{foo} = 'bar';
  $session->flush();
  $session = $starch->session( $session->key() );
  print $session->data->{foo}; # bar

=head1 DESCRIPTION

This is the session class used by L<Web::Starch/session>.

=cut

use Sereal;
use Scalar::Util qw( refaddr );
use Types::Standard -types;
use Types::Common::String -types;
use JSON::XS qw();
use Digest;
use Log::Any qw($log);

use Moo;
use strictures 1;
use namespace::clean;

my $compare_json = JSON::XS->new->canonical();

sub DEMOLISH {
  my ($self) = @_;

  if ($self->is_dirty() and !$self->is_deleted()) {
    $log->warnf(
      '%s %s was changed and not flushed',
      ref($self), $self->key(),
    );
  }

  return;
}

my $clone_encoder = Sereal::Encoder->new();
my $clone_decoder = Sereal::Decoder->new();

sub _clone {
  my ($data) = @_;

  return $clone_decoder->decode(
    $clone_encoder->encode( $data ),
  );
}

=head1 REQUIRED ARGUMENTS

=head2 starch

The L<Web::Starch> object which was used to create this session
object.  L<Web::Starch/session> automatically sets this.

=cut

has starch => (
  is       => 'ro',
  isa      => InstanceOf[ 'Web::Starch' ],
  required => 1,
);

=head1 OPTIONAL ARGUMENTS

=head2 key

The session key.  If one is not specified then one will be built and will
be considered new.

=cut

has _existing_key => (
  is       => 'ro',
  isa      => NonEmptySimpleStr,
  init_arg => 'key',
);

has key => (
  is       => 'lazy',
  isa      => NonEmptySimpleStr,
  init_arg => undef,
);
sub _build_key {
  my ($self) = @_;

  return $self->_existing_key() if !$self->is_new();

  my $digest = $self->digest();
  $digest->add( $self->hash_seed() );
  return $digest->hexdigest();
}

=head1 digest_algorithm

The L<Digest> algorithm which L</digest> will use.  Defaults to
C<SHA-1>.

=cut

has digest_algorithm => (
    is  => 'lazy',
    isa => NonEmptySimpleStr,
);
sub _build_digest_algorithm {
    return 'SHA-1';
}

=head1 ATTRIBUTES

=head2 original_data

The session data at the state it was when the session was first instantiated.

=cut

has original_data => (
  is     => 'lazy',
  isa    => HashRef,
  writer => '_set_original_data',
);
sub _build_original_data {
  my ($self) = @_;

  return {} if $self->is_new();

  my $data = $self->starch->store->get( $self->key() );
  $data //= {};

  return $data;
}

=head2 data

The session data which is meant to be modified.

=cut

has data => (
  is       => 'lazy',
  isa      => HashRef,
  init_arg => undef,
  writer   => '_set_data',
);
sub _build_data {
  my ($self) = @_;
  return _clone( $self->original_data() );
}

=head2 is_new

Returns true if the session is new (if the L</key> argument was not specified).

=cut

sub is_new {
  my ($self) = @_;
  return( $self->_existing_key() ? 0 : 1 );
}

=head2 is_deleted

Returns true if L</delete> has been called on this session.

=cut

has is_deleted => (
  is       => 'ro',
  isa      => Bool,
  default  => 0,
  writer   => '_set_is_deleted',
  init_arg => undef,
);

=head2 is_dirty

Returns true if the session data has changed (if L</original_data>
and L</data> are different).

=cut

sub is_dirty {
  my ($self) = @_;

  my $old = $compare_json->encode( $self->original_data() );
  my $new = $compare_json->encode( $self->data() );

  return 0 if $new eq $old;
  return 1;
}

=head1 METHODS

=head2 flush

If this session L</is_dirty> this will flush the L</data> to the
L<Web::Starch/store>.

=cut

sub flush {
  my ($self) = @_;
  return if !$self->is_dirty();
  return $self->force_flush();
}

=head2 force_flush

Like L</flush>, but flushes no matter what.

=cut

sub force_flush {
  my ($self) = @_;

  $self->starch->store->set(
    $self->key(),
    $self->data(),
  );

  $self->mark_clean();

  return;
}

=head2 mark_clean

Marks the session as not L</is_dirty> by setting L</original_data> to
L</data>.

=cut

sub mark_clean {
  my ($self) = @_;

  $self->_set_original_data(
    _clone( $self->data() ),
  );

  return;
}

=head2 rollback

Sets L</data> to L</original_data>.

=cut

sub rollback {
  my ($self) = @_;

  $self->_set_data(
    _clone( $self->original_data() ),
  );

  return;
}

=head2 delete

Deletes the session from the L<Web::Starch/store> and marks it
as L</is_deleted>.

=cut

sub delete {
  my ($self) = @_;

  $self->starch->store->remove( $self->key() );

  $self->_set_is_deleted( 1 );

  return;
}

=head2 hash_seed

Returns a fairly unique string used for seeding the L</key>'s digest hash.

=cut

my $counter = 0;
sub hash_seed {
  my ($self) = @_;
  return join( '', ++$counter, time, rand, $$, {}, refaddr($self) )
}

=head2 digest

Returns a new L<Digest> object set to the algorithm specified
by L</digest_algorithm>.

=cut

sub digest {
  my ($self) = @_;
  return Digest->new( $self->digest_algorithm() );
}

1;
