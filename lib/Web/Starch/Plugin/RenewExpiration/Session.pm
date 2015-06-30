package Web::Starch::Plugin::RenewExpiration::Session;

=head1 NAME

Web::Starch::Plugin::RenewExpiration::Session - Add methods to the Web::Starch::Session
for renewing storage session expirations.

=head1 DESCRIPTION

This role adds methods to L<Web::Starch::Session>.

See L<Web::Starch::Plugin::RenewExpiration> for examples of using this
module.

=cut

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
__END__

=head1 AUTHOR AND LICENSE

See L<Web::Starch/AUTHOR> and L<Web::Starch/LICENSE>.

