package Starch::Manager;

=head1 NAME

Starch::Manager - Entry point for accessing Starch state objects.

=head1 SYNOPSIS

See L<Starch>.

=head1 DESCRIPTION

This module provides a generic interface to managing the storage of
state data.

Typically you will be using the L<Starch> module to create this
object.

This class support method proxies as described in
L<Starch::Manual/METHOD PROXIES>.

=cut

use Starch::State;

use Types::Standard -types;
use Types::Common::String -types;
use Types::Common::Numeric -types;

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Role::Log
    Starch::Role::MethodProxy
);

sub BUILD {
    my ($self) = @_;

    # Get this built as early as possible.
    $self->store();

    return;
}

=head1 REQUIRED ARGUMENTS

=head2 store

The L<Starch::Store> storage backend to use for persisting the state
data.  A hashref must be passed and it is expected to contain at least a
C<class> key and will be converted into a store object automatically.

The C<class> can be fully qualified, or relative to the C<Starch::Store>
namespace.  A leading C<::> signifies that the store's package name is relative.

More information about stores can be found at L<Starch::Manual/STORES>.

=cut

has _store_arg => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
    init_arg => 'store',
);

has store => (
    is       => 'lazy',
    isa      => ConsumerOf[ 'Starch::Store' ],
    init_arg => undef,
);
sub _build_store {
    my ($self) = @_;

    my $store = $self->_store_arg();

    return $self->factory->new_store(
        %$store,
        manager => $self,
    );
}

=head1 OPTIONAL ARGUMENTS

=head2 expires

How long, in seconds, a state should live after the last time it was
modified.  Defaults to C<60 * 60 * 2> (2 hours).

See L<Starch::Manual/EXPIRATION> for more information.

=cut

has expires => (
    is       => 'ro',
    isa      => PositiveOrZeroInt,
    default => 60 * 60 * 2, # 2 hours
);

=head2 plugins

    my $starch = Starch->new(
        plugins     => ['::CookieArgs'],
        store       => ...,
        cookie_name => 'my_session',
    );
    my $state = $starch->state();
    print $state->cookie_args->{name}; # my_session

Which plugins to apply to the Starch objects, specified as an array
ref of plugin names.  The plugin names can be fully qualified, or
relative to the C<Starch::Plugin> namespace.  A leading C<::> signifies
that the plugin's package name is relative.

Plugins can modify nearly any functionality in Starch.  More information
about plugins, as well as which plugins are available, can be found at
L<Starch::Manual/PLUGINS>.

=cut

# This is a "virtual" argument of sorts handled in the modified new
# method.  The plugins end up being stored in the factory object.

=head2 expires_state_key

The state key to store the L<Starch::State/expires>
value in.  Defaults to C<__STARCH_EXPIRES__>.

=cut

has expires_state_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__STARCH_EXPIRES__',
);

=head2 modified_state_key

The state key to store the L<Starch::State/modified>
value in.  Defaults to C<__STARCH_MODIFIED__>.

=cut

has modified_state_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__STARCH_MODIFIED__',
);

=head2 created_state_key

The state key to store the L<Starch::State/created>
value in.  Defaults to C<__STARCH_CREATED__>.

=cut

has created_state_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__STATE_CREATED__',
);

=head2 invalid_state_key

This key is used by stores to mark state data as invalid,
and when set in the state will disable the state from being
written to the store.

This is used by the L<Starch::Plugin::LogStoreExceptions> and
L<Starch::Plugin::ThrottleStore> plugins to avoid losing state
data in the store when errors or throttling is encountered.

=cut

has invalid_state_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__STARCH_THROTTLED__',
);

=head2 factory

The underlying L<Starch::Factory> object which manages all the plugins
and state/store object construction.

=cut

has factory => (
    is  => 'lazy',
    isa => InstanceOf[ 'Starch::Factory' ],
);
sub _build_factory {
    my ($self) = @_;
    return Starch::Factory->new(
        base_manager_class => ref( $self ),
    );
}

=head1 METHODS

=head2 state

    my $new_state = $starch->state();
    my $existing_state = $starch->state( $id );

Returns a new L<Starch::State> (or whatever L<Starch::Factory/state_class>
returns) object for the specified state ID.

If no ID is specified, or is undef, then an ID will be automatically generated.

Additional arguments can be passed after the ID argument.  These extra
arguments will be passed to the state object constructor.

=cut

sub state {
    my $self = shift;
    my $id = shift;

    my $class = $self->factory->state_class();

    my $extra_args = $class->BUILDARGS( @_ );

    return $class->new(
        %$extra_args,
        manager => $self,
        defined($id) ? (id => $id) : (),
    );
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut

