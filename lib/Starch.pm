package Starch;

=head1 NAME

Starch - Implementation independent session management.

=head1 SYNOPSIS

    my $starch = Starch->new(
        expires => 60 * 15, # 15 minutes
        store => {
            class   => '::Memory',
        },
    );
    my $new_session = $starch->session();
    my $existing_session = $starch->session( $id );

=head1 DESCRIPTION

This module provides a generic interface to managing sessions and is
often refered to as the "manager" in this documentation.

Please see L<Starch::Manual> for some good holistic starter
documentation.

This class support method proxies as described in
L<Starch::Manual/METHOD PROXIES>.

=cut

use Starch::Factory;
use Starch::Session;

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

=head1 PLUGINS

    my $starch = Starch->new_with_plugins(
        ['::CookieArgs'],
        store => { class=>'::Memory' },
        cookie_name => 'my_session',
    );
    my $session = $starch->session();
    print $session->cookie_args->{name}; # my_session

Starch plugins are applied using the C<new_with_plugins> constructor method.
The first argument is an array ref of plugin names.  The plugin names can
be fully qualified, or relative to the C<Starch::Plugin> namespace.
A leading C<::> signifies that the plugin's package name is relative.

More information about plugins can be found at L<Starch::Manual/PLUGINS>.

=cut

sub new_with_plugins {
    my $class = shift;
    my $plugins = shift;

    my $args = $class->BUILDARGS( @_ );

    my $factory = Starch::Factory->new(
        plugins => $plugins,
        base_manager_class => $class,
    );

    return $factory->manager_class->new(
        %$args,
        factory => $factory,
    );
}

=head1 REQUIRED ARGUMENTS

=head2 store

The L<Starch::Store> storage backend to use for persisting the session
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

How long, in seconds, a session should live after the last time it was
modified.  Defaults to C<60 * 60 * 2> (2 hours).

See L<Starch::Manual/EXPIRATION> for more information.

=cut

has expires => (
    is       => 'ro',
    isa      => PositiveOrZeroInt,
    default => 60 * 60 * 2, # 2 hours
);

=head2 expires_session_key

The session key to store the L<Starch::Session/expires>
value in.  Defaults to C<__SESSION_EXPIRES__>.

=cut

has expires_session_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__SESSION_EXPIRES__',
);

=head2 modified_session_key

The session key to store the L<Starch::Session/modified>
value in.  Defaults to C<__SESSION_MODIFIED__>.

=cut

has modified_session_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__SESSION_MODIFIED__',
);

=head2 created_session_key

The session key to store the L<Starch::Session/created>
value in.  Defaults to C<__SESSION_CREATED__>.

=cut

has created_session_key => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '__SESSION_CREATED__',
);

=head2 factory

The underlying L<Starch::Factory> object which manages all the plugins
and session/store object construction.

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

=head2 session

    my $new_session = $starch->session();
    my $existing_session = $starch->session( $id );

Returns a new L<Starch::Session> (or whatever L<Starch::Factory/session_class>
returns) object for the specified session ID.

If no ID is specified, or is undef, then an ID will be automatically generated.

Additional arguments can be passed after the ID argument.  These extra
arguments will be passed to the session object constructor.

=cut

sub session {
    my $self = shift;
    my $id = shift;

    my $class = $self->factory->session_class();

    my $extra_args = $class->BUILDARGS( @_ );

    return $class->new(
        %$extra_args,
        manager => $self,
        defined($id) ? (id => $id) : (),
    );
}

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 CONTRIBUTORS

=over

=item *

Arthur Axel "fREW" Schmidt <frioux+cpanE<64>gmail.com>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

