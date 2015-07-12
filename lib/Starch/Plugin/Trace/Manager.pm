package # hide from PAUSE
    Starch::Plugin::Trace::Manager;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForManager
);

sub BUILD {
    my ($self) = @_;
    $self->log->trace( 'starch.manager.new' );
    return;
}

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
