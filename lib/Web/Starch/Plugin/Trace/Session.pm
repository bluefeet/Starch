package Web::Starch::Plugin::Trace::Session;

=head1 NAME

Web::Starch::Plugin::Trace::Session - Add extra trace logging to your sessions.

=head1 DESCRIPTION

See L<Web::Starch::Plugin::Trace>.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForSession
);

=head1 LOGGING

=head2 new

Every time a L<Web::Starch::Session> object is created a message is
logged in the format of C<starch.session.new.$session_key>.

=cut

sub BUILD {
    my ($self) = @_;
    $self->log->tracef(
        'starch.session.new.%s',
        $self->id(),
    );
    return;
}

=head2 save

Every call to L<Web::Starch::Session/force_save> (which C<save> calls
if the session isn't dirty) is logged in the format of
C<starch.session.save.$session_id>.

=cut

around force_save => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.session.save.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

=head2 reload

Every call to L<Web::Starch::Session/force_reload> (which C<reload> calls
if the session isn't dirty) is logged in the format of
C<starch.session.reload.$session_id>.

=cut

around force_reload => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.session.reload.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

=head2 mark_clean

Every call to L<Web::Starch::Session/mark_clean>
is logged in the format of C<starch.session.mark_clean.$session_id>.

=cut

around mark_clean => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.session.mark_clean.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

=head2 rollback

Every call to L<Web::Starch::Session/rollback>
is logged in the format of C<starch.session.rollback.$session_id>.

=cut

around rollback => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.session.rollback.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

=head2 delete

Every call to L<Web::Starch::Session/force_delete> (which C<delete> calls
if the session is in the store) is logged in the format of
C<starch.session.delete.$session_id>.

=cut

around force_delete => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.session.delete.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

=head2 generate_id

Every call to L<Web::Starch::Session/generate_id>
is logged in the format of C<starch.session.generate_id.$session_id>.

=cut

around generate_id => sub{
    my $orig = shift;
    my $self = shift;

    my $id = $self->$orig( @_ );

    $self->log->tracef(
        'starch.session.generate_id.%s',
        $id,
    );

    return $id;
};

1;
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.

