#!/usr/bin/env perl
use 5.008001;
use strictures 2;

use Test2::V0;
use Test::Starch;
use Starch;

{
    package Test::TiedHash;
    use strictures 2;

    require Tie::Hash;

    our @ISA = qw( Tie::StdHash );
    our @LOG;

    sub STORE {
        my $self = shift;
        push @LOG, [ 'STORE', @_ ];
        return $self->SUPER::STORE( @_ );
    }

    sub FETCH {
        my $self = shift;
        push @LOG, [ 'FETCH', @_ ];
        return $self->SUPER::FETCH( @_ );
    }
}

my %starch_args = (
    plugins => ['::TiedHash'],
    tied_hash_class => 'Test::TiedHash',
);

Test::Starch->new( %starch_args )->test();

my $starch = Starch->new(
    %starch_args,
    store => { class => '::Memory' },
);

subtest tied_hash => sub{
    @Test::TiedHash::LOG = ();

    my $state = $starch->state();
    isa_ok tied( $state->data->%* ), ['Test::TiedHash'], 'data hash is tied';

    $state->data->{tester} = 34;
    is $state->data->{tester}, 34, 'tied hash stored and fetched a value';

    is(
        \@Test::TiedHash::LOG,
        [
            [ 'STORE', 'tester', 34 ],
            [ 'FETCH', 'tester' ],
        ],
        'tied class was excercised',
    );
};

done_testing;
