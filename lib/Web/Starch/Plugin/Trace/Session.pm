package Web::Starch::Plugin::Trace::Session;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForSession
);

sub BUILD {
    my ($self) = @_;
    $self->log->tracef(
        'starch.session.new.%s',
        $self->id(),
    );
    return;
}

around force_save => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.session.save.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

around force_reload => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.session.reload.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

around mark_clean => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.session.mark_clean.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

around rollback => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.session.rollback.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

around force_delete => sub{
    my $orig = shift;
    my $self = shift;

    $self->log->tracef(
        'starch.session.delete.%s',
        $self->id(),
    );

    return $self->$orig( @_ );
};

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
