package # hide from PAUSE
    Starch::Plugin::Trace::Store;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForStore
);

sub BUILD {
    my ($self) = @_;
    $self->log->tracef(
        'starch.store.%s.new',
        $self->_trace_log_name(),
    );
    return;
}

around set => sub{
    my $orig = shift;
    my $self = shift;
    my ($id) = @_;

    $self->log->tracef(
        'starch.store.%s.set.%s',
        $self->_trace_log_name(), $id,
    );

    return $self->$orig( @_ );
};

around get => sub{
    my $orig = shift;
    my $self = shift;
    my ($id) = @_;

    $self->log->tracef(
        'starch.store.%s.get.%s',
        $self->_trace_log_name(), $id,
    );

    my $data = $self->$orig( @_ );

    $self->log->tracef(
        'starch.store.%s.get.%s.missing',
        $self->_trace_log_name(), $id,
    ) if !$data;

    return $data;
};

around remove => sub{
    my $orig = shift;
    my $self = shift;
    my ($id) = @_;

    $self->log->tracef(
        'starch.store.%s.remove.%s',
        $self->_trace_log_name(), $id,
    );

    return $self->$orig( @_ );
};

sub _trace_log_name {
    my ($self) = @_;
    my $name = ref( $self );
    $name =~ s{^Starch::Store::}{};
    $name =~ s{__WITH__.*$}{};
    return $name;
}

1;
