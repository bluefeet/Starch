package # hide from PAUSE
    Starch::Plugin::RenewExpiration::State;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForState
);

around save => sub{
    my $orig = shift;
    my $self = shift;

    return $self->$orig( @_ ) if $self->is_dirty();

    return if !$self->is_loaded();
    return if $self->is_saved();
    return if $self->is_deleted();

    my $manager = $self->manager();

    my $thresh = $manager->renew_threshold();
    if ($thresh > 0) {
        my $variance = $manager->renew_variance();
        if ($variance > 0) {
            my $delta = int($thresh * $variance);
            $thresh = ($thresh - $delta) + int( rand($delta+1) );
        }

        my $modified = $self->modified();
        return if $modified + $thresh > time();
    }

    return $self->force_save();
};

1;
