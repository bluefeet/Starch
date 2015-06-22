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

Drop-in replacements for various framework session systems will be
implemented, such as
L<Catalyst::Plugin::Starch> and L<Plack::Middleware::Starch>.

The inspiration of this module was the complexity and performance
issues with L<Catalyst::Plugin::Session>.  When using
L<Devel::NYTProf> on my Catalyst apps, at 2 separate jobs, I
found that Catalyst::Plugin::Session was a substantial contributor
to slow response times due to its deep stack of subroutine calls and,
in this author's opinion, overly complex architecture.

This module aims to be as fast as possible and be independent from
any particular framework which makes writing unit tests easier
for this distribution and for you as an implementor.

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

# I tried creating a custom type with coercion and failed miserably.
# Even then, this code is easier to understand and follow.
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

    $store = { %$store };
    my $suffix = delete $store->{class};
    croak "No class key was declared in the Web::Starch store hash ref"
        if !defined $suffix;

    my $class = $self->factory->store_class( $suffix );
    my $args = $class->BUILDARGS( $store );

    return $class->new(
        %$args,
        factory => $self->factory(),
    );
}

=head1 OPTIONAL ARGUMENTS

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
    my $existing_session = $starch->session( $key );

Returns a new L<Web::Starch::Session> (or whatever L<Web::Starch::Factory/session_class>
returns) object for the specified key.

If no key is specified, or is undef, then a key will be automatically generated.

Additional arguments can be passed after the key argument.  These extra
arguments will be passed to the session object constructor.

=cut

sub session {
    my $self = shift;
    my $key = shift;

    my $class = $self->factory->session_class();

    my $extra_args = $class->BUILDARGS( @_ );

    return $class->new(
        %$extra_args,
        starch => $self,
        defined($key) ? (key => $key) : (),
    );
}

1;
__END__

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

Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

