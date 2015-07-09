package Web::Starch::Session;

=head1 NAME

Web::Starch::Session - The Web::Starch session object.

=head1 SYNOPSIS

    my $session = $starch->session();
    $session->data->{foo} = 'bar';
    $session->save();
    $session = $starch->session( $session->id() );
    print $session->data->{foo}; # bar

=head1 DESCRIPTION

This is the session class used by L<Web::Starch/session>.

=cut

use Scalar::Util qw( refaddr );
use Types::Standard -types;
use Types::Common::String -types;
use Digest::SHA qw( sha1_hex );
use Carp qw( croak );
use Storable qw( freeze dclone );

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Role::Log
);

sub DEMOLISH {
    my ($self) = @_;

    if ($self->is_dirty()) {
        $self->log->errorf(
            'Starch session %s was changed and not saved.',
            $self->id(),
        );
    }

    return;
}

=head1 REQUIRED ARGUMENTS

=head2 manager

The L<Web::Starch> object that glues everything together.  The session
object needs this to get at configuration information and the stores.
This argument is automatically set by L<Web::Starch/session>.

=cut

has manager => (
    is       => 'ro',
    isa      => InstanceOf[ 'Web::Starch' ],
    required => 1,
);

=head1 OPTIONAL ARGUMENTS

=head2 id

The session ID.  If one is not specified then one will be built and
the session will be considered new.

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
    init_arg  => undef,
    writer    => '_set_original_data',
    clearer   => '_clear_original_data',
    predicate => 'is_loaded',
);
sub _build_original_data {
    my ($self) = @_;

    return {} if !$self->in_store();

    my $data = $self->manager->store->get( $self->id() );
    $data = {} if !$data;

    return $data;
}

=head2 data

The session data which is meant to be modified.

=cut

has data => (
    is       => 'lazy',
    init_arg => undef,
    writer   => '_set_data',
    clearer  => '_clear_data',
);
sub _build_data {
    my ($self) = @_;
    return $self->clone_data( $self->original_data() );
}

=head2 expires

This defaults to L<Web::Starch/expires> and is stored in the L</data>
under the L<Web::Starch/expires_session_key> key.

=cut

has expires => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => '_clear_expires',
    writer   => '_set_expires',
);
sub _build_expires {
    my ($self) = @_;

    my $manager = $self->manager();
    my $expires = $self->original_data->{ $manager->expires_session_key() };

    $expires = $manager->expires() if !defined $expires;

    return $expires;
}

=head2 modified

Whenever the session is L</save>d this will be updated and stored in
L</data> under the L<Web::Starch/modified_session_key>.

=cut

has modified => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => '_clear_modified',
);
sub _build_modified {
    my ($self) = @_;

    my $modified = $self->original_data->{
        $self->manager->modified_session_key()
    };

    $modified = $self->created() if !defined $modified;

    return $modified;
}

=head2 created

When the session is created this is set and stored in L</data>
under the L<Web::Starch/created_session_key>.

=cut

has created => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => '_clear_created',
);
sub _build_created {
    my ($self) = @_;

    my $created = $self->original_data->{
        $self->manager->created_session_key()
    };

    $created = time() if !defined $created;

    return $created;
}

=head2 in_store

Returns true if the session is expected to exist in the store
(AKA, if the L</id> argument was specified or L</save> was called).

=cut

has in_store => (
    is       => 'lazy',
    writer   => '_set_in_store',
    init_arg => undef,
);
sub _build_in_store {
    my ($self) = @_;
    return( $self->_has_existing_id() ? 1 : 0 );
}

=head2 is_deleted

Returns true if L</delete> has been called on this session.

=cut

has is_deleted => (
    is       => 'ro',
    writer   => '_set_is_deleted',
    init_arg => undef,
    default  => 0,
);

=head2 is_dirty

Returns true if the session data has changed (if L</original_data>
and L</data> are different).

=cut

sub is_dirty {
    my ($self) = @_;

    return 0 if $self->is_deleted();

    # If we haven't even loaded the data from the store then
    # there is no way we're dirty.
    return 0 if !$self->is_loaded();

    return $self->is_data_diff( $self->original_data(), $self->data() );
}

=head2 is_loaded

This returns true if the L</original_data> has been loaded up from
the session store.  Note that L</original_data> will be automatically
loaded if L</original_data>, L</data>, or any methods that call them,
are called.

=cut

# This is provided by the original_data attribute via its predicate.

=head2 is_saved

Returns true if the session was saved and is not dirty.

=cut

has _save_was_called => (
    is       => 'ro',
    writer   => '_set_save_was_called',
    init_arg => undef,
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

    croak 'Cannot call save or force_save on a deleted session'
        if $self->is_deleted();

    my $manager = $self->manager();
    my $data = $self->data();

    $data->{ $manager->created_session_key() }  = $self->created();
    $data->{ $manager->modified_session_key() } = time();
    $data->{ $manager->expires_session_key() }  = $self->expires();

    $manager->store->set(
        $self->id(),
        $data,
        $self->expires(),
    );

    $self->_set_in_store( 1 );
    $self->_set_save_was_called( 1 );

    $self->mark_clean();

    $self->_clear_expires();
    $self->_clear_modified();
    $self->_clear_created();

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

    return if $self->is_deleted();

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

    return if $self->is_deleted();

    $self->_set_original_data(
        $self->clone_data( $self->data() ),
    );

    return;
}

=head2 rollback

Sets L</data> to L</original_data>.

=cut

sub rollback {
    my ($self) = @_;

    return if $self->is_deleted();

    $self->_set_data(
        $self->clone_data( $self->original_data() ),
    );

    return;
}

=head2 delete

Deletes the session from the L<Web::Starch/store> and marks it
as L</is_deleted>.  Throws an exception if not L<in_store>.

=cut

sub delete {
    my ($self) = @_;

    croak 'Cannot call delete on a session that is not stored yet'
        if !$self->in_store();

    return $self->force_delete();
}

=head2 force_delete

Just like L</delete>, but remove the session from the store even if
the session is not L</in_store>.

=cut

sub force_delete {
    my ($self) = @_;

    $self->manager->store->remove( $self->id() );

    $self->_set_original_data( {} );
    $self->_set_data( {} );
    $self->_set_is_deleted( 1 );
    $self->_set_in_store( 0 );

    return;
}

=head2 set_expires

    # Extend this session's expires duration by two hours.
    $session->set_expires( $session->expires() + (2 * 60 * 60) );

Use this to set the session's expires to a duration different than the
global expires set by L<Web::Starch/expires>.  This is useful for,
for example, to support a "Remember Me" checkbox that many login
forms provide where the difference between the user checking it or not
is just a matter of what the session's expires duration is set to.

Remember that the "expires" duration is a measurement, in seconds, of
how long the session will live in the store since the last modification,
and how long the cookie (if you are using cookies) will live since the
last request.

The expires duration can be more than or less than the global expires,
there is no artificial constraint.

=cut

sub set_expires {
    my ($self, $expires) = @_;

    $self->_set_expires( $expires );
    $self->data->{ $self->manager->expires_session_key() } = $expires;

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

=head2 generate_id

Generates and returns a new session ID which is a SHA-1 hex
digest of calling L</hash_seed>.

=cut

sub generate_id {
    my ($self) = @_;
    return sha1_hex( $self->hash_seed() );
}

=head2 reset_id

=cut

sub reset_id {
    my ($self) = @_;

    # Remove the data for the current session ID.
    $self->manager->store->remove( $self->id() ) if $self->in_store();

    # Ensure that future calls to id generate a new one.
    $self->_clear_existing_id();
    $self->_clear_id();

    # Make sure the session data is now dirty so it gets saved.
    $self->_set_original_data( {} );
    $self->_set_save_was_called( 0 );

    return;
}

=head2 clone_data

Clones complex perl data structures.  Used internally to build
L</data> from L</original_data>.

=cut

sub clone_data {
    my ($self, $data) = @_;
    return dclone( $data );
}

=head2 is_data_diff

Given two bits of data (scalar, array ref, or hash ref) this returns
true if the data is different.  Used internally by L</is_dirty>.

=cut

sub is_data_diff {
    my ($self, $old, $new) = @_;

    local $Storable::canonical = 1;

    $old = freeze( $old );
    $new = freeze( $new );

    return 0 if $new eq $old;
    return 1;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Web::Starch/AUTHOR>, L<Web::Starch/CONTRIBUTORS>, and L<Web::Starch/LICENSE>.

