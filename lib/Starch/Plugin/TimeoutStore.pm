package Starch::Plugin::TimeoutStore;

=head1 NAME

Starch::Plugin::TimeoutStore - Throw an exception if store access surpass a timeout.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::TimeoutStore'],
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
a web page even if the underlying store backend is failing, so
using this plugin with L<Starch::Plugin::LogStoreExceptions> is
probably a good idea.

Note that this plugin does not behave well on Perl 5.8 or older and will
error if you try to use it on a version of Perl older than 5.10.  The rest
of Starch works well on 5.8 and up.

=cut

use 5.010_000;

use Time::HiRes qw();
use Try::Tiny;
use Carp qw( croak );
use Types::Common::Numeric -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForStore
);

=head1 OPTIONAL STORE ARGUMENTS

These arguments are added to classes which consume the
L<Starch::Store> role.

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

around sub_store_args => sub{
    my $orig = shift;
    my $self = shift;

    my $args = $self->$orig( @_ );

    return {
        timeout => $self->timeout(),
        %$args,
    };
};

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut

