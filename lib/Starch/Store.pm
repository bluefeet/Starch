package Starch::Store;

=head1 NAME

Starch::Store - Base role for Starch stores.

=head1 DESCRIPTION

This role defines an interfaces for Starch store classes.  Starch store
classes are meant to be thin wrappers around the store implementations
(such as DBI, CHI, etc).

See L<Starch/STORES> for instructions on using stores and a list of
available Starch stores.

See L</WRITING> for instructions on writing your own stores.

This role adds support for method proxies to consuming classes as
described in L<Starch/METHOD PROXIES>.

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
    return if $data->{ $self->manager->invalid_state_key() };

    $expires = $self->calculate_expires( $expires );

    return $self->$orig( $id, $keys, $data, $expires );
};

=head1 REQUIRED ARGUMENTS

=head2 manager

The L<Starch::Manager> object which is used by stores to
create sub-stores (such as the Layered store's outer and inner
stores).  This is automatically set when the stores are built by
L<Starch::Factory>.

=cut

has manager => (
    is       => 'ro',
    isa      => InstanceOf[ 'Starch::Manager' ],
    required => 1,
    weak_ref => 1,
    handles  => ['factory'],
);

=head1 OPTIONAL ARGUMENTS

=head2 max_expires

Set the per-store maximum expires which will override the state's expires
if the state's expires is larger.

=cut

has max_expires => (
    is  => 'ro',
    isa => PositiveOrZeroInt | Undef,
);

=head2 key_separator

Used by L</combine_keys> to combine the state keys.
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
        $state_id,
        \@namespace,
    );

This method is used by stores that store and lookup data by
a string (all of them at this time).  It combines the state
ID with the namespace of the key data for the store request
(usually just C<['state']>).  Plugins may implement other
namespace keys to segregate different state data into
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

This triggers the store to find and delete all expired states.
This is meant to be used in an offline process, such as a cronjob,
as finding and deleting the states could take hours depending
on the amount of data and the storage engine's speed.

By default this method will throw an exception if the store does
not define its own reap method.  You can check if a store supports
this method by calling L</can_reap_expired>.

=cut

sub reap_expired {
    my ($self) = @_;

    croak sprintf(
        '%s does not support expired state reaping',
        $self->base_class_name(),
    );
}

1;
__END__

=head1 WRITING

Stores provide the data persistence layers for stores so that, from HTTP request
to request, the data set in the store is available to get.

See L<Starch::Store::Memory> for a basic example store.  See
L<Starch::Manual/STORES> for more existing stores.

A store must implement the C<set>, C<get>, and C<remove> methods and consume
the L<Starch::Store> role.

Writing new stores is generally a trivial process where the store class does
nothing more than glue those three methods with some underlying implementation
such as L<DBI> or L<CHI>.

Stores should be written so that the underlying driver object (the C<$dbh>
for a DBI store, for example) can be passed as an argument.   This allows
the user to utilize L<Starch/METHOD PROXIES> to build their
own driver objects.

Some boilerplate for getting a store going:

    package Starch::Store::FooBar;
    
    use Foo::Bar;
    use Types::Standard -types;
    
    use strictures 2;
    use namespace::clean;
    use Moo;
    
    with qw(
        Starch::Store
    );
    
    has foobar => (
        is => 'lazy',
        isa => InstanceOf[ 'Foo::Bar' ],
    );
    sub _build_foobar {
        return Foo::Bar->new();
    }
    
    sub set {
        my ($self, $id, $namespace, $data, $expires) = @_;
        my $key = $self->combine_keys( $id, $namespace );
        $self->foobar->set( $key, $data, $expires );
        return;
    }
    
    sub get {
        my ($self, $id, $namespace) = @_;
        my $key = $self->combine_keys( $id, $namespace );
        return $self->foobar->get( $key );
    }
    
    sub remove {
        my ($self, $id, $namespace) = @_;
        my $key = $self->combine_keys( $id, $namespace );
        $self->foobar->remove( $key );
        return;
    }
    
    1;
`
Many stores benefit from building their lazy-loaded driver object early,
as in:

    sub BUILD {
        my ($self) = @_;
        $self->foobar();
        return;
    }

A state's expires duration is stored in the state data under the
L<Starch::Manager/expires_state_key>.  This should B<not> be considered
as anything meaningful to the store, since stores can have their
L<Starch::Store/max_expires> argument set which will automatically
change the value of the C<expiration> argument passed to C<set>.

=head2 REQUIRED METHODS

A more detailed description of the methods that a store must
implement:

=over

=item *

B<set> - Sets the data for the key.  The C<$expires> value will always be set and
will be either C<0> or a positive integer representing the number of seconds
in the future that this state data should be expired.  If C<0> then the
store may expire the data whenever it chooses.

=item *

B<get> - Returns the data for the given key.  If the data was not found then
C<undef> is returned.

=item *

B<remove> - Deletes the data for the key.  If the data does not exist then
this is just a no-op.

=back

These method receive a state ID and a namespace array ref as their
first two arguments.  The combination of these two values should identify
a unique storage location in the store.  They can be combined to create a
single key string using L<Starch::Store/combine_keys>.

=head2 EXCEPTIONS

Stores should detect issues and throw exceptions loudly.  If the user
would like to automatically turn store exceptions into log messages
they can use the L<Starch::Plugin::LogStoreExceptions> plugin.

=head2 REAPING EXPIRED STATES

Stores may choose to support an interface for deleting old state data
suitable for a cronjob.  To do this two methods must be declared:

    sub can_reap_expired { 1 }
    
    sub reap_expired {
        my ($self) = @_;
        
        # Do whatever it takes to delete expired state data.
        ...
        # and, call $self->log->info() at important moments so that user
        # can see some progress.
        
        return;
    }

The actual implementation of how to reap old state data is a per-store
and is something that will differ greatly between them.

Consider adding extra arguments to your store class to control how state
reaping functions.  For example, a DBI store may allow the user to reap
the states in batches, and a DynamoDB store may allow the user to specify
a secondary global index to do the scan on.

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut

