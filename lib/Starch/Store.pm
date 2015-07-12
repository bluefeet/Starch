package Starch::Store;

=head1 NAME

Starch::Store - Role for session stores.

=head1 DESCRIPTION

This role defines an interfaces for session store classes.  Session store
classes are meant to be thin wrappers around the store implementations
(such as DBI, CHI, etc).

See L<Starch::Manual/STORES> for instructions on using stores and a
list of available session stores.

See L<Starch::Manual::Extending/STORES> for instructions on writing
your own stores.

This role adds support for method proxies to consuming classes as
described in L<Starch::Manual/METHOD PROXIES>.

=cut

use Types::Standard -types;
use Types::Common::Numeric -types;
use Types::Common::String -types;
use Carp qw( croak );

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Role::Log
    Starch::Role::MethodProxy
);

requires qw(
    set
    get
    remove
);

around set => sub{
    my ($orig, $self, $id, $keys, $data, $expires) = @_;

    # Short-circuit set operations if the data is invalid.
    return if $data->{ $self->manager->invalid_session_key() };

    $expires = $self->calculate_expires( $expires );

    return $self->$orig( $id, $keys, $data, $expires );
};

=head1 REQUIRED ARGUMENTS

=head2 manager

The L<Starch> object which is used by stores to
create sub-stores (such as the Layered store's outer and inner
stores).  This is automatically set when the stores are built by
L<Starch::Factory>.

=cut

has manager => (
    is       => 'ro',
    isa      => InstanceOf[ 'Starch' ],
    required => 1,
    weak_ref => 1,
    handles  => ['factory'],
);

=head1 OPTIONAL ARGUMENTS

=head2 max_expires

Set the per-store maximum expires which will override the session's expires
if the session's expires is larger.

=cut

has max_expires => (
    is  => 'ro',
    isa => PositiveOrZeroInt | Undef,
);

=head2 key_separator

Used by L</combine_keys> to combine the session keys.
Defaults to C<:>.

=cut

has key_separator => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => ':',
);

=head1 ATTRIBUTES

=head2 can_reap_expired

Return true if the stores supports the L</reap_expired> method.

=cut

sub can_reap_expired { 0 }

=head2 short_store_class_name

Returns L<Starch::Role::Log/short_class_name> with the
C<Store::> prefix remove.

=cut

sub short_store_class_name {
    my ($self) = @_;
    my $class = $self->short_class_name();
    $class =~ s{^Store::}{};
    return $class;
}

=head1 METHODS

=head2 new_sub_store

Builds a new store object.  Any arguments passed will be
combined with the L</sub_store_args>.

=cut

sub new_sub_store {
    my $self = shift;

    my $args = $self->sub_store_args( @_ );

    return $self->factory->new_store( $args );
}

=head2 sub_store_args

Returns the arguments needed to create a sub-store.  Any arguments
passed will be combined with the default arguments.  The default
arguments will be L</manager> and L</max_expires> (if set).  More
arguments may be present if any plugins extend this method.

=cut

sub sub_store_args {
    my $self = shift;

    my $max_expires = $self->max_expires();

    my $args = $self->BUILDARGS( @_ );

    return {
        manager       => $self->manager(),
        max_expires   => $max_expires,
        key_separator => $self->key_separator(),
        %$args,
    };
}

=head2 calculate_expires

Given an expires value this will calculate the expires that this store
should use considering what L</max_expires> is set to.

=cut

sub calculate_expires {
    my ($self, $expires) = @_;

    my $max_expires = $self->max_expires();
    return $expires if !defined $max_expires;

    return $max_expires if $expires > $max_expires;

    return $expires;
}

=head2 combine_keys

    my $store_key = $store->combine_keys(
        $session_id,
        \@namespace,
    );

This method is used by stores that store and lookup data by
a string (all of them at this time).  It combines the session
ID with the namespace of the key data for the store request
(usually just C<['session']>).  Plugins may implement other
namespace keys to segregate different session data into
separate reads and writes in the store.

=cut

sub combine_keys {
    my ($self, $id, $namespace) = @_;
    return join(
        $self->key_separator(),
        @$namespace,
        $id,
    );
}

=head2 reap_expired

This triggers the store to find and delete all expired sessions.
This is meant to be used in an offline process, such as a cronjob,
as finding and deleting the sessions could take hours depending
on the amount of data and the storage engine's speed.

By default this method will throw an exception if the store does
not define its own reap method.  You can check if a store supports
this method by calling L</can_reap_expired>.

=cut

sub reap_expired {
    my ($self) = @_;

    croak sprintf(
        '%s does not support expired session reaping',
        $self->base_class_name(),
    );
}

1;
__END__

=head1 METHODS

All store classes must implement the C<set>, C<get>, and C<remove> methods.

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

