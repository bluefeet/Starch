package # hide from PAUSE
    Web::Starch::Plugin::RenewExpiration::Session;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForSession
);

sub DEMOLISH {
    my ($self) = @_;

    return if !$self->is_loaded();
    return if $self->is_saved();
    return if $self->is_deleted();

    my $thresh = $self->manager->renew_threshold();
    if ($thresh > 0) {
        my $modified = $self->modified();
        return if $modified + $thresh > time();
    }

    $self->force_save();

    return;
}

1;
