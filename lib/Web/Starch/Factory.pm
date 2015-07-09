package Web::Starch::Factory;

=head1 NAME

Web::Starch::Factory - Role applicator and class creator.

=head1 DESCRIPTION

This class consumes the L<Web::Starch::Plugin::Bundle> role and
is used by L<Web::Starch> to apply specified plugins to manager,
session, and store classes.

Normally there is no need to interact with this class directly.

=cut

use Moo::Role qw();
use Types::Standard -types;
use Carp qw( croak );
use Moo::Object qw();
use Web::Starch::Util qw( load_prefixed_module );
use Module::Runtime qw( require_module );

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::Bundle
);

=head1 OPTIONAL ARGUMENTS

=head2 plugins

This is the L<Web::Starch::Plugin::Bundle/plugins> attribute, but altered
to be an argument.

=cut

has '+plugins' => (
    init_arg => 'plugins',
);
sub bundled_plugins {
    return [];
}

=head2 base_manager_class

The base class of the Starch manager object.  Default to C<Web::Starch>.

=cut

has base_manager_class => (
    is  => 'lazy',
    isa => ClassName,
);
sub _build_base_manager_class {
    return 'Web::Starch';
}

=head2 base_session_class

The base class of Starch session objects.  Default to C<Web::Starch::Session>.

=cut

has base_session_class => (
    is  => 'lazy',
    isa => ClassName,
);
sub _build_base_session_class {
    return 'Web::Starch::Session';
}

=head1 ATTRIBUTES

=head2 manager_class

The anonymous class which extends L</base_manager_class> and has
L</manager_roles> applied to it.

=cut

has manager_class => (
    is       => 'lazy',
    isa      => ClassName,
    init_arg => undef,
);
sub _build_manager_class {
    my ($self) = @_;

    my $roles = $self->manager_roles();
    my $class = $self->base_manager_class();
    require_module( $class );

    return $class if !@$roles;

    return Moo::Role->create_class_with_roles( $class, @$roles );
}

=head2 session_class

The anonymous class which extends L</base_session_class> and has
L</session_roles> applied to it.

=cut

has session_class => (
    is       => 'lazy',
    isa      => ClassName,
    init_arg => undef,
);
sub _build_session_class {
    my ($self) = @_;

    my $roles = $self->session_roles();
    my $class = $self->base_session_class();
    require_module( $class );

    return $class if !@$roles;

    return Moo::Role->create_class_with_roles( $class, @$roles );
}

=head1 METHODS

=head2 base_store_class

    my $class = $factory->base_store_class( 'Memory' );
    # Web::Starch::Store::Memory
    
    my $class = $factory->base_store_class( 'Web::Starch::Store::Memory' );
    # Web::Starch::Store::Memory

Given an absolute or relative store class name this will
return the resolved class name.

=cut

sub base_store_class {
    my ($self, $suffix) = @_;

    return load_prefixed_module(
        'Web::Starch::Store',
        $suffix,
    );
}

=head2 store_class

    my $class = $factory->store_class( 'Memory' );

Given an absolute or relative store class name this will
return an anonymous class which extends the store class
and has L</store_roles> applied to it.

=cut

sub store_class {
    my ($self, $suffix) = @_;

    my $roles = $self->store_roles();
    my $class = $self->base_store_class( $suffix );

    return $class if !@$roles;

    return Moo::Role->create_class_with_roles( $class, @$roles );
}

=head2 new_store

    my $store = $factory->new_store( class=>'::Memory', %args );

Creates and returns a new L</store_class> object with the
factory argument set.

Note that since the L<Web::Starch::Store/expires> argument is
required you must specify it.

=cut

sub new_store {
    my $self = shift;

    my $args = Moo::Object->BUILDARGS( @_ );
    $args = { %$args };
    my $suffix = delete $args->{class};
    croak "No class key was declared in the Web::Starch store hash ref"
        if !defined $suffix;

    my $class = $self->store_class( $suffix );
    return $class->new(
        %$args,
    );
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Web::Starch/AUTHOR>, L<Web::Starch/CONTRIBUTORS>, and L<Web::Starch/LICENSE>.

