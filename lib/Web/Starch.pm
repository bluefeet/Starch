package Web::Starch;

=head1 NAME

Web::Starch - Implementation independent session management.

=head1 SYNOPSIS

    my $starch = Web::Starch->new(
        store => {
            class   => '::Memory',
            expires => 60 * 15, # 15 minutes
        },
    );
    my $new_session = $starch->session();
    my $existing_session = $starch->session( $key );

=head1 DESCRIPTION

This module provides a generic interface to managing sessions, AKA the
session manager.

This module aims to be as fast as possible and be independent from
any particular framework which makes writing unit tests easier
for this distribution and for you as an implementor.

This class consumes the L<Web::Starch::Component> role, but modifies
the C<manager> attribute to just return itself.

=cut

use Web::Starch::Factory;
use Web::Starch::Session;

use Moo::Role qw();
use Types::Standard -types;
use Types::Common::String -types;
use Scalar::Util qw( blessed );
use Carp qw( croak );

use Moo;
use strictures 1;
use namespace::clean;

with qw(
    Web::Starch::Component
);

sub BUILD {
    my ($self) = @_;

    # Get this built as early as possible.
    $self->store();

    return;
}

=head1 PLUGINS

    my $starch = Web::Starch->new_with_plugins(
        ['::CookieArgs'],
        store => { class=>'::Memory' },
        cookie_name => 'my_session',
    );
    my $session = $starch->session();
    print $session->cookie_args->{name}; # my_session

Starch plugins are applied using the C<new_with_plugins> constructor method.
The first argument is an array ref of plugin names.  The plugin names can
be fully qualified, or relative to C<Web::Starch::Plugin>.  A leading C<::>
signifies that the plugin's package name is relative.

=cut

sub new_with_plugins {
    my $class = shift;
    my $plugins = shift;

    my $args = $class->BUILDARGS( @_ );

    my $factory = Web::Starch::Factory->new(
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

The L<Web::Starch::Store> storage backend to use for persisting the session
data.  If a hashref is passed it is expected to contain at least a C<class>
key and will be blessed into a store object automatically.

The C<class> can be fully qualified, or relative to C<Web::Starch::Store>.
A leading C<::> signifies that the store's package name is relative.

The class must implement the C<set>, C<get>, and C<remove> methods.  Typically
a store class consumes the L<Web::Starch::Store> role which enforces this interface.

To find available stores you can search
L<meta::cpan|https://metacpan.org/search?q=Web%3A%3AStarch%3A%3AStore>.

Stores can be layered, such as if you want to put a cache in front of your
session database by using the L<Web::Starch::Store::Layered> store.

=cut

has _store_arg => (
    is       => 'ro',
    isa      => HasMethods[ 'set', 'get', 'remove' ] | HashRef,
    required => 1,
    init_arg => 'store',
);

has store => (
    is       => 'lazy',
    isa      => HasMethods[ 'set', 'get', 'remove' ],
    init_arg => undef,
);
sub _build_store {
    my ($self) = @_;

    my $store = $self->_store_arg();
    return $store if blessed $store;

    return $self->factory->new_store( $store );
}

=head1 OPTIONAL ARGUMENTS

=head1 digest_algorithm

The L<Digest> algorithm which L<Web::Starch::Session/digest> will use.
Defaults to C<SHA-1>.

=cut

has digest_algorithm => (
    is  => 'lazy',
    isa => NonEmptySimpleStr,
);
sub _build_digest_algorithm {
    return 'SHA-1';
}

=head2 factory

The underlying L<Web::Starch::Factory> object which manages all the plugins
and session/store object construction.

=cut

has factory => (
    is  => 'lazy',
    isa => HasMethods[ 'session_class', 'store_class' ],
);
sub _build_factory {
    my ($self) = @_;
    return Web::Starch::Factory->new(
        base_manager_class => ref( $self ),
    );
}

=head1 METHODS

=head2 session

    my $new_session = $starch->session();
    my $existing_session = $starch->session( $id );

Returns a new L<Web::Starch::Session> (or whatever L<Web::Starch::Factory/session_class>
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

=head2 OBJECT REFERENCES

                                                          +------+
                                                          v      |
    +------------------------+       +------------------------+  |
    |        manager         | ----> |          store         |--+
    |     (Web::Starch)      |       |  (Web::Starch::Store)  |
    +------------------------+       +------------------------+
                    ^     |                       |
                    |     +------------+          |
                    |                  v          v
    +------------------------+       +------------------------+
    |        session         |       |        factory         |
    | (Web::Starch::Session) |       | (Web::Starch::Factory) |
    +------------------------+       +------------------------+

This diagram shows which objects hold references to other objects.

=head1 DEPENDENCIES

The C<Web-Starch> distribution is shipped with minimal dependencies
and with no non-core XS requirements.  This is important for many people.

=head1 SUPPORT

Please submit bugs and feature requests on GitHub issues:

L<https://github.com/bluefeet/Web-Starch/issues>

=head1 ALTERNATIVES

=over

=item *

L<CGI::Session>

=item *

L<Data::Session>

=item *

L<HTTP::Session>

=item *

L<Catalyst::Plugin::Session>

=item *

L<Plack::Middleware::Session>

=item *

L<Dancer::Session>

=item *

L<Mojolicious::Sessions>

=item *

L<MojoX::Session>

=back

Unlike these modules this module tries to make as little assumptions
as possible and just provides raw session management with the ability
for implementors to alter behaviors as they see fit.

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

