package Web::Starch::Session;

=head1 NAME

Web::Starch::Session - The starch session object.

=head1 SYNOPSIS

    my $session = $starch->session();
    $session->data->{foo} = 'bar';
    $session->save();
    $session = $starch->session( $session->id() );
    print $session->data->{foo}; # bar

=head1 DESCRIPTION

This is the session class used by L<Web::Starch/session>.

This class consumes the L<Web::Starch::Component> role.

=cut

use Scalar::Util qw( refaddr );
use Types::Standard -types;
use Types::Common::String -types;
use Digest;
use Carp qw( croak );
use Storable qw( freeze dclone );

use Moo;
use strictures 1;
use namespace::clean;

with qw(
    Web::Starch::Component
);

sub DEMOLISH {
    my ($self) = @_;

    if ($self->is_dirty()) {
        $self->log->errorf(
            '%s %s was changed and not saved.',
            ref($self), $self->id(),
        );
    }

    return;
}

=head1 REQUIRED ARGUMENTS

=head2 manager

The L<Web::Starch> object that glues everything together.  The session
object needs this to get at configuration information and the stores.

=cut

has manager => (
    is       => 'ro',
    isa      => InstanceOf[ 'Web::Starch' ],
    required => 1,
);

=head1 OPTIONAL ARGUMENTS

=head2 id

The session ID.  If one is not specified then one will be built and will
be considered new.

=cut

has _existing_id => (
    is        => 'ro',
    isa       => NonEmptySimpleStr,
    init_arg  => 'id',
    predicate => 1,
    clearer   => '_clear_existing_id',
);

has id => (
    is       => 'lazy',
    isa      => NonEmptySimpleStr,
    init_arg => undef,
    clearer  => '_clear_id',
);
sub _build_id {
    my ($self) = @_;
    return $self->_existing_id() if $self->_has_existing_id();
    return $self->generate_id();
}

=head1 ATTRIBUTES

=head2 original_data

The session data at the state it was when the session was first instantiated.

=cut

has original_data => (
    is        => 'lazy',
    isa       => HashRef,
    writer    => '_set_original_data',
    clearer   => '_clear_original_data',
    predicate => '_has_original_data',
);
sub _build_original_data {
    my ($self) = @_;

    return {} if !$self->in_store();

    my $data = $self->manager->store->get( $self->id() );
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
    clearer  => '_clear_data',
);
sub _build_data {
    my ($self) = @_;
    return $self->clone( $self->original_data() );
}

=head2 in_store

Returns true if the session is expected to exist in the store
(AKA, if the L</id> argument was specified).

=cut

has in_store => (
    is     => 'lazy',
    isa    => Bool,
    writer => '_set_in_store',
);
sub _build_in_store {
    my ($self) = @_;
    return( $self->_has_existing_id() ? 1 : 0 );
}

=head2 is_expired

Returns true if L</expire> has been called on this session.

=cut

has is_expired => (
    is       => 'lazy',
    isa      => Bool,
    writer   => '_set_is_expired',
    init_arg => undef,
);
sub _build_is_expired {
    return 0;
}

=head2 is_dirty

Returns true if the session data has changed (if L</original_data>
and L</data> are different).

=cut

sub is_dirty {
    my ($self) = @_;

    return 0 if $self->is_expired();

    # If we haven't even loaded the data from the store then
    # there is no way we're dirty.
    return 0 if !$self->_has_original_data();

    local $Storable::canonical = 1;

    my $old = freeze( $self->original_data() );
    my $new = freeze( $self->data() );

    return 0 if $new eq $old;
    return 1;
}

=head2 is_saved

Returns true if the session was saved and is not dirty.

=cut

has _save_was_called => (
  is     => 'ro',
  isa    => Bool,
  wrtier => '_set_save_was_called',
);

sub is_saved {
  my ($self) = @_;
  return 0 if !$self->_save_was_called();
  return 0 if $self->is_dirty();
  return 1;
}

=head1 METHODS

=head2 save

If this session L</is_dirty> this will save the L</data> to the
L<Web::Starch/store>.

=cut

sub save {
    my ($self) = @_;
    return if !$self->is_dirty();
    return $self->force_save();
}

=head2 force_save

Like L</save>, but saves even if L</is_dirty> is not set.

=cut

sub force_save {
    my ($self) = @_;

    croak 'Cannot call save or force_save on an expired session'
        if $self->is_expired();

    $self->manager->store->set(
        $self->id(),
        $self->data(),
    );

    $self->_set_in_store( 1 );
    $self->_save_was_called( 1 );

    $self->mark_clean();

    return;
}

=head2 reload

Clears L</original_data> and L</data> so that the next call to these
will reload the session data from the store.  If the session L</is_dirty>
then an exception will be thrown.

=cut

sub reload {
    my ($self) = @_;

    croak 'Cannot call reload on a dirty session'
        if $self->is_dirty();

    return $self->force_reload();
}

=head2 force_reload

Just like L</reload>, but reloads even if the session L</is_dirty>.

=cut

sub force_reload {
    my ($self) = @_;

    return if $self->is_expired();

    $self->_clear_original_data();
    $self->_clear_data();

    return;
}

=head2 mark_clean

Marks the session as not L</is_dirty> by setting L</original_data> to
L</data>.

=cut

sub mark_clean {
    my ($self) = @_;

    return if $self->is_expired();

    $self->_set_original_data(
        $self->clone( $self->data() ),
    );

    return;
}

=head2 rollback

Sets L</data> to L</original_data>.

=cut

sub rollback {
    my ($self) = @_;

    return if $self->is_expired();

    $self->_set_data(
        $self->clone( $self->original_data() ),
    );

    return;
}

=head2 expire

Deletes the session from the L<Web::Starch/store> and marks it
as L</is_expired>.  Throws an exception if not L<in_store>.

=cut

sub expire {
    my ($self) = @_;

    croak 'Cannot call expire on a session that is not stored yet'
        if !$self->in_store();

    return $self->force_expire();
}

=head2 force_expire

Just like L</expire>, but remove the session from the store even if
the session is not L</in_store>.

=cut

sub force_expire {
    my ($self) = @_;

    $self->manager->store->remove( $self->id() );

    $self->_set_original_data( {} );
    $self->_set_data( {} );
    $self->_set_is_expired( 1 );
    $self->_set_in_store( 0 );

    return;
}

=head2 hash_seed

Returns a fairly unique string used for seeding L</id>.

=cut

my $counter = 0;
sub hash_seed {
    my ($self) = @_;
    return join( '', ++$counter, time, rand, $$, {}, refaddr($self) )
}

=head2 digest

Returns a new L<Digest> object set to the algorithm specified
by L<Web::Starch/digest_algorithm>.

=cut

sub digest {
    my ($self) = @_;
    return Digest->new( $self->manager->digest_algorithm() );
}

=head2 generate_id

Generates and returns a new session ID using the L</hash_seed>
passed to the L</digest>.  This is used by L</id> if no id arugment
was specified.

=cut

sub generate_id {
    my ($self) = @_;

    my $digest = $self->digest();
    $digest->add( $self->hash_seed() );
    return $digest->hexdigest();
}

=head2 reset_id

=cut

sub reset_id {
    my ($self) = @_;

    # Remove the data for the current session ID.
    $self->manager->session( $self->id() )->expire();

    # Ensure that future calls to id generate a new one.
    $self->_clear_existing_id();
    $self->_clear_id();

    # Make sure the session data is now dirty so it gets saved.
    $self->_set_original_data( {} );

    return;
}

=head1 CLASS METHODS

=head2 clone

Clones complex perl data structures.  Used internally to build
L</data> from L</original_data>.

=cut

sub clone {
    my ($class, $data) = @_;
    return dclone( $data );
}

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.

