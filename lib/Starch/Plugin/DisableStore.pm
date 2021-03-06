package Starch::Plugin::DisableStore;
our $VERSION = '0.14';

=encoding utf8

=head1 NAME

Starch::Plugin::DisableStore - Disable store read and/or write operations.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::DisableStore'],
        store => {
            class => ...,
            disable_set => 1,
        },
    );

=head1 DESCRIPTION

This plugin provides the ability to make stores silently fail
read and write operations.  This can be useful for migrating
from one store to another where it doesn't make sense to write
to the old store, only read.

=cut

use Types::Standard -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Starch::Plugin::ForStore';

=head1 OPTIONAL STORE ARGUMENTS

These arguments are added to classes which consume the
L<Starch::Store> role.

=head2 disable_set

Setting this to true makes the C<set> method silently fail.

=head2 disable_get

Setting this to true makes the C<get> method silently fail and
return undef.

=head2 disable_remove

Setting this to true makes the C<remove> method silently fail.

=cut

foreach my $method (qw( set get remove )) {
    my $argument = "disable_$method";

    has $argument => (
        is  => 'ro',
        isa => Bool,
    );

    around $method => sub{
        my $orig = shift;
        my $self = shift;

        return $self->$orig( @_ ) if !$self->$argument();

        return undef if $method eq 'get';
        return;
    };
}

around sub_store_args => sub{
    my $orig = shift;
    my $self = shift;

    my $args = $self->$orig( @_ );

    return {
        disable_set    => $self->disable_set(),
        disable_get    => $self->disable_get(),
        disable_remove => $self->disable_remove(),
        %$args,
    };
};

1;
__END__

=head1 SUPPORT

See L<Starch/SUPPORT>.

=head1 AUTHORS

See L<Starch/AUTHORS>.

=head1 COPYRIGHT AND LICENSE

See L<Starch/COPYRIGHT AND LICENSE>.

=cut

