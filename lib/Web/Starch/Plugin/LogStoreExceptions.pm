package Web::Starch::Plugin::LogStoreExceptions;

=head1 NAME

Web::Starch::Plugin::LogStoreExceptions - Turn Starch store exceptions into log messages.

=head1 SYNOPSIS

    my $starch = Web::Starch->new_with_plugins(
        ['::LogStoreExceptions'],
        ...,
    );

=head1 DESCRIPTION

This plugin causes any exceptions thrown when C<set>, C<get>, or C<remove> is
called on a store to produce an error log message instead of an exception.

Typically you'll want to use this in production, as the session store being
down is often not enough of a reason to produce 500 errors on every page.

This plugin should be listed last in the plugin list so that it catches
exceptions produced by other plugins.

=cut

use Try::Tiny;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForStore
);

foreach my $method (qw( set get remove )) {
    around $method => sub{
        my $orig = shift;
        my $self = shift;

        my @args = @_;

        return try {
            return $self->$orig( @args );
        }
        catch {
            $self->log->errorf(
                'Starch store %s errored when %s was called: %s',
                ref($self), $method, $_,
            );
            return undef;
        };
    };
}

1;
