package Web::Starch::Plugin::Trace::Manager;

=head1 NAME

Web::Starch::Plugin::Trace::Manager - Add extra trace logging to your manager.

=head1 DESCRIPTION

See L<Web::Starch::Plugin::Trace>.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForManager
);

=head1 LOGGING

=head2 new

Every time a L<Web::Starch> object is created a message is
logged in the format of C<starch.manager.new>.

=cut

sub BUILD {
    my ($self) = @_;
    $self->log->trace( 'starch.manager.new' );
    return;
}

=head2 session

Every call to L<Web::Starch/session> is logged in the
format of C<starch.manager.session.$action.$session_id>, where
C<$action> is either C<retrieve> or C<create> depending
on if the session ID was provided.

=cut

around session => sub{
    my $orig = shift;
    my $self = shift;
    my ($id) = @_;

    my $session = $self->$orig( @_ );

    $self->log->tracef(
        'starch.manager.session.%s.%s',
        defined($id) ? 'retrieved' : 'created',
        $session->id(),
    );

    return $session;
};

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.

