package Web::Starch::Store::Memory;

=head1 NAME

Web::Starch::Store::Memory - In-memory session store.

=head1 DESCRIPTION

This store provides an in-memory store using a Perl Hash to store the
data.  This store is mostly here as a proof of concept and for writing
tests against.

=cut

use Types::Standard -types;
use Types::Common::Numeric -types;

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Store
);

=head1 OPTIONAL ARGUMENTS

=head2 global

Set this to a true value to use a shared memory store for all instances
of this class that enable this argument.

=cut

my $global_memory = {};

has global => (
    is  => 'ro',
    isa => Bool,
);

=head1 ATTRIBUTES

=head2 memory

This is the hash ref which is used for storing sessions.

=cut

has memory => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_memory {
    my ($self) = @_;
    return $global_memory if $self->global();
    return {};
}

=head1 METHODS

=head2 set

Set L<Web::Starch::Store/set>.

=head2 get

Set L<Web::Starch::Store/get>.

=head2 remove

Set L<Web::Starch::Store/remove>.

=cut

sub set {
    my ($self, $key, $data) = @_;

    $self->memory->{$key} = $data;

    return;
}

sub get {
    my ($self, $key) = @_;
    return $self->memory->{$key};
}

sub remove {
    my ($self, $key) = @_;
    delete( $self->memory->{$key} );
    return;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Web::Starch/AUTHOR>, L<Web::Starch/CONTRIBUTORS>, and L<Web::Starch/LICENSE>.

