package Web::Starch::Plugin::TimeoutStores;

=head1 NAME

Web::Starch::Plugin::TimeoutStores - Throw an exception if stores surpass a timeout.

=head1 SYNOPSIS

    my $starch = Web::Starch->new_with_plugins(
        ['::TimeoutStores'],
        store => {
            class => '::Memory',
            timeout => 0.001, # 1 millisecond
        },
        ...,
    );

=head1 DESCRIPTION

This plugin causes all calls to C<set>, C<get>, and C<remove> to throw
an exception if they surpass a timeout period.

The timeout is implemented using L<Time::HiRes>'s C<alarm> function,
which takes fractional seconds, and a localized C<$SIG{ALRM}> handler.

The whole point of detecting timeouts is so that you can still serve
a web page even if the underlying session backend is failing, so
using this plugin with L<Web::Starch::Plugin::LogStoreExceptions> is
probably a good idea.

=cut

use Time::HiRes qw();
use Try::Tiny;
use Carp qw( croak );
use Types::Common::Numeric -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Web::Starch::Plugin::ForStore
);

=head1 OPTIONAL ARGUMENTS

=head2 timeout

How many seconds to timeout.  Set to C<0> to disable timeout
checking.  Defaults to C<0>.

=cut

has timeout => (
    is      => 'ro',
    isa     => PositiveOrZeroNum,
    default => 0,
);

foreach my $method (qw( set get remove )) {
    around $method => sub{
        my $orig = shift;
        my $self = shift;

        my $timeout = $self->timeout();
        return $self->$orig( @_ ) if $timeout == 0;

        my @args = @_;

        return try {
            local $SIG{ALRM} = sub{
                die 'STARCH TIMEOUT ALARM TRIGGERED';
            };
            Time::HiRes::alarm( $timeout );
            my @ret;
            @ret = $self->$orig( @args );
            Time::HiRes::alarm( 0 );
            return( @ret ? $ret[0] : () );
        }
        catch {
            croak sprintf(
                'Starch store %s method %s exceeded the timeout of %s seconds',
                ref($self), $method, $timeout,
            ) if $_ =~ m{STARCH TIMEOUT ALARM TRIGGERED};
            die $_;
        };
    };
}

1;
