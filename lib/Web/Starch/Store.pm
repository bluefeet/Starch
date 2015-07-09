package Web::Starch::Store;

=head1 NAME

Web::Starch::Store - Role for session stores.

=head1 DESCRIPTION

This role defines an interfaces for session store classes.  Session store
classes are meant to be thin wrappers around the store implementations
(such as DBI, CHI, etc).

See L<Web::Starch::Manual/STORES> for instructions on using stores and a
list of available session stores.

See L<Web::Starch::Manual::Extending/STORES> for instructions on writing
your own stores.

This role adds support for method proxies to consuming classes as
described in L<Web::Starch::Manual/METHOD PROXIES>.

=cut

use Types::Standard -types;
use Types::Common::Numeric -types;
use Carp qw( croak );

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Role::Log
    Web::Starch::Role::MethodProxy
);

requires qw(
    set
    get
    remove
);

around set => sub{
    my ($orig, $self, $key, $data, $expires) = @_;

    $expires = $self->calculate_expires( $expires );

    return $self->$orig( $key, $data, $expires );
};

=head1 REQUIRED ARGUMENTS

=head2 manager

The L<Web::Starch> object which is used by stores to
create sub-stores (such as the Layered store's outer and inner
stores).  This is automatically set when the stores are built by
L<Web::Starch::Factory>.

=cut

has manager => (
    is       => 'ro',
    isa      => InstanceOf[ 'Web::Starch' ],
    required => 1,
    weak_ref => 1,
    handles => ['factory'],
);

=head1 OPTIONAL ARGUMENTS

=head2 max_expires

Set the per-store maximum expires wich will override the session's expires
if the session's expires is larger.

=cut

has max_expires => (
  is  => 'ro',
  isa => PositiveOrZeroInt | Undef,
);

=head1 ATTRIBUTES

=head2 can_reap_expired

Return true if the stores supports the L</reap_expired> method.

=cut

sub can_reap_expired { 0 }

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
        manager => $self->manager(),
        defined($max_expires) ? (max_expires => $max_expires) : (),
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

=head2 base_class_name

Returns the store's class name minus the C<__WITH__.*> suffix put on
by plugins.  This is used to produce more concise error output.

=cut

sub base_class_name {
    my ($self) = @_;
    my $class = ref( $self );
    $class =~ s{__WITH__.*$}{};
    return $class;
}

1;
__END__

=head1 METHODS

All store classes must implement the C<set>, C<get>, and C<remove> methods.

=head1 AUTHORS AND LICENSE

See L<Web::Starch/AUTHOR>, L<Web::Starch/CONTRIBUTORS>, and L<Web::Starch/LICENSE>.

