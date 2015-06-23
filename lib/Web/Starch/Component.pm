package Web::Starch::Component;

=head1 NAME

Web::Starch::Component - Shared role for all starch components.

=head1 DESCRIPTION

This role provides some common functionality that the manager
(L<Web::Starch>), session (L<Web::Starch::Session>) and store
(L<Web::Starch::Store>) share.

=cut

use Types::Standard -types;
use Log::Any;

use Moo::Role;
use strictures 2;
use namespace::clean;

=head1 ATTRIBUTES

=head2 log

A L<Log::Any::Proxy> object with the category set to the
object's package.

=cut

has log => (
    is       => 'lazy',
    isa      => InstanceOf[ 'Log::Any::Proxy' ],
    init_arg => undef,
);
sub _build_log {
    my ($self) = @_;
    return Log::Any->get_logger(category => ref($self));
}

1;
