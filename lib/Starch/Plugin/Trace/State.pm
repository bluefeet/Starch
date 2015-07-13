package # hide from PAUSE
    Starch::Plugin::Trace::State;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForState
);

sub BUILD {
    my ($self) = @_;
    $self->log->tracef(
        'starch.state.new.%s',
        $self->id(),
    );
    return;
}

around force_save => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.state.save.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

around force_reload => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.state.reload.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

around mark_clean => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.state.mark_clean.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

around rollback => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.state.rollback.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

around force_delete => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.state.delete.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

around generate_id => sub{
    my $orig = shift;
    my $self = shift;

    my $id = $self->$orig( @_ );

    $self->log->tracef(
        'starch.state.generate_id.%s',
        $id,
    );

    return $id;
};

1;
