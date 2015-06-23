package Web::Starch::Session;

=head1 NAME

Web::Starch::Session - The starch session object.

=head1 SYNOPSIS

    my $session = $starch->session();
    $session->data->{foo} = 'bar';
    $session->save();
    $session = $starch->session( $session->key() );
    print $session->data->{foo}; # bar

=head1 DESCRIPTION

This is the session class used by L<Web::Starch/session>.

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

sub DEMOLISH {
    my ($self) = @_;

    if ($self->is_dirty() and !$self->is_expired()) {
        warn sprintf(
            '%s %s was changed and not saved',
            ref($self), $self->key(),
        );
    }

    return;
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
    is        => 'ro',
    isa       => NonEmptySimpleStr,
    init_arg  => 'key',
    predicate => 1,
);

has key => (
    is       => 'lazy',
    isa      => NonEmptySimpleStr,
    init_arg => undef,
);
sub _build_key {
    my ($self) = @_;

    return $self->_existing_key() if $self->_has_existing_key();

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
    is      => 'lazy',
    isa     => HashRef,
    writer  => '_set_original_data',
    clearer => '_clear_original_data',
);
sub _build_original_data {
    my ($self) = @_;

    return {} if !$self->in_store();

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
    clearer  => '_clear_data',
);
sub _build_data {
    my ($self) = @_;
    return $self->clone( $self->original_data() );
}

=head2 in_store

Returns true if the session is expected to exist in the store
(AKA, if the L</key> argument was specified).

=cut

has in_store => (
    is     => 'lazy',
    isa    => Bool,
    writer => '_set_in_store',
);
sub _build_in_store {
    my ($self) = @_;
    return( $self->_has_existing_key() ? 1 : 0 );
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

    local $Storable::canonical = 1;

    my $old = freeze( $self->original_data() );
    my $new = freeze( $self->data() );

    return 0 if $new eq $old;
    return 1;
}

=head1 METHODS

=head2 save

If this session L</is_dirty> this will save the L</data> to the
L<Web::Starch/store> and L</reload> the session.

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

    $self->starch->store->set(
        $self->key(),
        $self->data(),
    );

    $self->force_reload();

    $self->_set_in_store( 1 );

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

Just like L</reload>, but reloads even if the session L</is dirty>.

=cut

sub force_reload {
    my ($self) = @_;

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

    $self->_set_data(
        $self->clone( $self->original_data() ),
    );

    return;
}

=head2 expire

Deletes the session from the L<Web::Starch/store> and marks it
as L</is_expired>.

=cut

sub expire {
    my ($self) = @_;

    $self->starch->store->remove( $self->key() );

    $self->_set_is_expired( 1 );
    $self->_set_in_store( 0 );

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
