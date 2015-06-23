package Web::Starch::Plugin::Trace;

use Moo;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::Bundle
);

sub bundled_plugins {
    return [qw(
        ::Trace::Manager
        ::Trace::Session
        ::Trace::Store
    )];
}

1;
__END__

=head1 NAME

Web::Starch::Plugin::Trace - Add extra trace logging to your manager,
sessions, and stores.

=head1 SYNOPSIS

    my $starch = Web::Starch->new(
        plugins => ['Trace'],
        ...,
    );

=head1 DESCRIPTION

This plugin bundle logs a lot of debug information to L<Log::Any> under the
C<trace> level.  See
L<Web::Starch::Plugin::Trace::Manager>,
L<Web::Starch::Plugin::Trace::Session>,
and L<Web::Starch::Plugin::Trace::Store>
for details about what exactly is logged.

See the L<Log::Any> documentation for instructions on how to output
these log messages using an adapter.

The the individual C<::Trace> plugins can be used
independently so that, for example, you could enable trace logging on the
store only by enabling just the C<::Trace::Store> plugin.

This plugin is meant for development as logging will reduce performance.

