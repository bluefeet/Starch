package Web::Starch::Plugin::Trace::Store;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForStore
);

sub BUILD {
    my ($self) = @_;
    $self->log->trace( 'starch.store.new' );
    return;
}

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
    ) if !$data;

    return $data;
};

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
