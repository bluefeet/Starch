package Web::Starch;

=head1 NAME

Web::Starch - Implementation independent session management.

=head1 SYNOPSIS

    my $starch = Web::Starch->new(
        store => {
            class   => 'Memory',
            expires => 60 * 15, # 15 minutes
        },
    );
    my $new_session = $starch->session();
    my $existing_session = $starch->session( $key );

=head1 DESCRIPTION

This module provides a generic interface to managing sessions.

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

use Web::Starch::Session;
use Moo::Role qw();
use Types::Standard -types;
use Types::Common::String -types;
use Scalar::Util qw( blessed );
use Class::Load qw( load_optional_class );
use Carp qw( croak );

use Moo;
use strictures 1;
use namespace::clean;

=head1 REQUIRED ARGUMENTS

=head2 store

The L<Web::Starch::Store> storage backend to use for persisting the session
data.  If a hashref is passed it is expected to contain at least a C<class>
key and will be blessed into a store object automatically.

The C<class> key's value must be a fully qualified package name of a class
which implements the C<set>, C<get>, and C<remove> methods.  Typically
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

    my $class_prefix = $store->{class};
    croak "No class key was declared in the Web::Starch store hash ref"
        if !defined $class_prefix;

    foreach my $class(
        "Web::Starch::Store::$class_prefix",
        $class_prefix,
    ) {
        next if !load_optional_class($class);
        return $class->new( $store );
    }

    croak "Could not find a store class with the name Web::Starch::Store::$class_prefix or $class_prefix";
}

=head1 OPTIONAL ARGUMENTS

=head2 session_class

The class that L</session> will use for constructing session objects.  Defaults
to L<Web::Starch::Session>, but you can override this with your own sub-class.

If you specify L</session_traits> then an anonymous class will be returned
which will be a subclass of Web::Starch::Session (or, if the class you specified
if you provided the session_class argument) with the traits applied to it.

See L</EXTENDING>.

=cut

# Use two attributes here to represent the single session_class attribute.
# This is done so that a custom session class and session traits can both
# be declared and they will be combined to create the final session class.

has _session_class_arg => (
    is       => 'lazy',
    isa      => ClassName,
    init_arg => 'session_class',
    builder  => '_build_session_class_arg',
);
sub _build_session_class_arg {
    return 'Web::Starch::Session';
}

has session_class => (
    is       => 'lazy',
    isa      => ClassName,
    init_arg => undef,
);
sub _build_session_class {
    my ($self) = @_;

    my $class = $self->_session_class_arg();

    my $traits = $self->session_traits();
    return $class if !@$traits;

    my @actual_traits;
    foreach my $trait_prefix (@$traits) {
        my $trait_found = 0;
        foreach my $trait (
            "Web::Starch::Session::Trait::$trait_prefix",
            $trait_prefix,
        ) {
            next if !load_optional_class( $trait );
            $trait_found = 1;
            push @actual_traits, $trait;
            last;
        }

        next if $trait_found;
        croak "Could not find a session trait with the name Web::Starch::Session::Trait::$trait_prefix or $trait_prefix";
    }

    return Moo::Role->create_class_with_roles(
        $class,
        @actual_traits,
    );
}

=head2 session_traits

A list of L<Moo::Role> roles.  These roles will be applied by
L</session_class>.  The role names may be specified without the
C<Web::Starch::Store::> suffix.

See L</EXTENDING>.

=cut

has session_traits => (
    is  => 'lazy',
    isa => ArrayRef[ NonEmptySimpleStr ],
);
sub _build_session_traits {
    return [];
}

=head2 session_args

A hash ref of arguments that will be included in the session's
constructor arguments when L</session> is called.

=cut

has session_args => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_session_args {
    return {};
}

=head1 METHODS

=head2 session

    my $new_session = $starch->session();
    my $existing_session = $starch->session( $key );

Returns a new L<Web::Starch::Session> (or whetever L</session_class> is set
to) object for the specified key.

If no key is specified then a key will be automatically generated.

=cut

sub session {
    my ($self, $key) = @_;

    return $self->session_class->new(
        %{ $self->session_args() },
        starch => $self,
        defined($key) ? (key => $key) : (),
    );
}

1;
__END__

=head1 EXTENDING

Below is per-package explanations about how to extend Web::Starch.

Besides the documented public API any C<_build_*> methods are fair game
to apply method modifiers to in your sub-classes and roles (except where
otherwise noted below).

=head2 Web::Starch::Session

The most common extensions involve modifying the functionality of the
session objects.  The simplest way to do this is by creating Moo roles
and applying them via the L</session_traits> argument.  This would look
something like;

    package My::Session::Trait;
    use Moo::Role;
    sub foo { ... }
    
    my $starch = Web::Starch->new(
        ...,
        session_traits => ['My::Session::Trait'],
    );
    my $session = $starch->session();
    $session->foo();

Alternatively you can create your own subclass of L<Web::Starch::Session>
which would look like:

    package My::Session;
    use Moo;
    extends 'ZR::Starch::Session';
    sub foo { ... }
    
    my $starch = Web::Starch->new(
        ...,
        session_class 'My::Session',
    );
    my $session = $starch->session();
    $session->foo();

=head2 Web::Starch::Store

If you'd like to create a new store class see the
L<Web::Starch::Store> documentation.

=head2 Web::Starch

Extending the C<$starch> object, while not really a common practice,
is a matter of sub-clasing:

    package My::Starch;
    use Moo;
    extends 'Web::Starch';
    sub _build_default_session_class { 'My::Starch::Session' }

Note that you should override/modify C<_build_default_session_class>
rather than C<_build_session_class> as doing the latter would cause
L</session_traits> to be ignored which would be breaking the inherited
public API.

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

