package Web::Starch::Plugin::Trace::Store;

=head1 NAME

Web::Starch::Plugin::Trace::Store - Add extra trace logging to your store.

=head1 DESCRIPTION

See L<Web::Starch::Plugin::Trace>.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForStore
);

=head1 LOGGING

=head2 new

Every time a L<Web::Starch::Store> object is created a message is
logged in the format of C<starch.store.new>.

=cut

sub BUILD {
    my ($self) = @_;
    $self->log->trace( 'starch.store.new' );
    return;
}

=head1 set

Every call to L<Web::Starch::Store/set> is logged in the
format of C<starch.store.set.$session_id>.

=cut

around set => sub{
    my $orig = shift;
    my $self = shift;
    my ($id) = @_;

    $self->log->tracef(
        'starch.store.set.%s',
        $id,
    );

    return $self->$orig( @_ );
};

=head1 get

Every call to L<Web::Starch::Store/get> is logged in the
format of C<starch.store.get.$session_id>.

If the result of calling C<get> is undefined then an additional
log will produced of the format C<starch.store.get.$session_id.missing>.

=cut

around get => sub{
    my $orig = shift;
    my $self = shift;
    my ($id) = @_;

    $self->log->tracef(
        'starch.store.get.%s',
        $id,
    );

    my $data = $self->$orig( @_ );

    $self->log->tracef(
        'starch.store.get.%s.missing',
        $id,
    ) if !defined $data;

    return $data;
};

=head1 remove

Every call to L<Web::Starch::Store/remove> is logged in the
format of C<starch.store.remove.$session_id>.

=cut

around remove => sub{
    my $orig = shift;
    my $self = shift;
    my ($id) = @_;

    $self->log->tracef(
        'starch.store.remove.%s',
        $id,
    );

    return $self->$orig( @_ );
};

1;
