package Test::Starch;

=head1 NAME

Test::Starch - Test core features of starch.

=head1 SYNOPSIS

    use Test::More;
    
    my $tester = Test::Starch->new(
        plugins => [ ... ],
        args => { ... },
    );
    $tester->test();
    
    done_testing;

=head1 DESCRIPTION

This class runs the core L<Starch> test suite by testing public
interfaces of L<Starch>, L<Starch::Session>, and
L<Starch::Store>.  These are the same tests that Starch runs
when you install it from CPAN.

This module is used by stores and plugins to ensure that they have
not broken any of the core features of Starch.  All store and plugin
authors are highly encouraged to run these tests as part of their
test suite.

Along the same lines, it is recommended that if you use Starch that
you make a test in your in-house test-suite which runs these tests
againts your configuration.

=cut

use Types::Standard -types;
use Types::Common::String -types;

use Starch;
use Test::More;
use Test::Fatal;

use Moo;
use strictures 2;
use namespace::clean;

has plugins => (
    is      => 'ro',
    isa     => ArrayRef[ NonEmptySimpleStr ],
    default => sub{ [] },
);

has args => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub{ {
        store => { class=>'::Memory' },
    } },
);

has manager_class => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => 'Starch',
);

sub new_manager {
    my $self = shift;

    return $self->manager_class->new_with_plugins(
        $self->plugins(),
        %{ $self->args() },
        @_,
    );
}

=head1 METHODS

=head2 test

Calls L</test_manager>, L</test_session>, and L</test_store>.

=cut

sub test {
    my ($self) = @_;
    $self->test_manager();
    $self->test_session();
    $self->test_store();
    return;
}

=head2 test_manager

Tests L<Starch>.

=cut

sub test_manager {
    my ($self) = @_;

    my $starch = $self->new_manager();

    subtest 'core tests for ' . ref($starch) => sub{
        ok( 1 );
    };

    return;
}

=head2 test_session

Test L<Starch::Session>.

=cut

sub test_session {
    my ($self) = @_;

    my $starch = $self->new_manager();

    subtest 'core tests for ' . ref($starch->session()) => sub{
        subtest id => sub{
            my $session1 = $starch->session();
            my $session2 = $starch->session();
            my $session3 = $starch->session( '1234' );

            like( $session1->id(), qr{^\S+$}, 'ID looks good' );
            isnt( $session1->id(), $session2->id(), 'two generated session IDs are not the same' );
            is( $session3->id(), '1234', 'custom ID was used' );
        };

        subtest expires => sub{
            my $session = $starch->session();
            is( $session->expires(), $starch->expires(), 'session expires inherited the global expires' );
        };

        subtest modified => sub{
            my $session = $starch->session();
            is( $session->modified(), $session->created(), 'modfied is same as created in new session' );
            sleep 2;
            $session->force_save();
            $session = $starch->session( $session->id() );
            cmp_ok( $session->modified(), '>', $session->created(), 'modified was updated with save' );
        };

        subtest created => sub{
            my $start_time = time();
            my $session = $starch->session();
            my $created_time = $session->created();
            cmp_ok( $created_time, '>=', $start_time, 'session created on or after test start' );
            cmp_ok( $created_time, '<=', $start_time+1, 'session created is on or just after test start' );
            sleep 2;
            $session->force_save();
            $session = $starch->session( $session->id() );
            is( $session->created(), $created_time, 'created was updated with save' );
        };

        subtest in_store => sub{
            my $session1 = $starch->session();
            my $session2 = $starch->session( $session1->id() );

            is( $session1->in_store(), 0, 'new session is_new' );
            is( $session2->in_store(), 1, 'existing session is not is_new' );
        };

        subtest is_deleted => sub{
            my $session = $starch->session();
            is( $session->is_deleted(), 0, 'new session is not deleted' );
            $session->force_save();
            $session->delete();
            is( $session->is_deleted(), 1, 'deleted session is deleted' );
        };

        subtest is_dirty => sub{
            my $session = $starch->session();
            is( $session->is_dirty(), 0, 'new session is not is_dirty' );
            $session->data->{foo} = 543;
            is( $session->is_dirty(), 1, 'modified session is_dirty' );
        };

        subtest is_loaded => sub{
            my $session = $starch->session();
            ok( (!$session->is_loaded()), 'session is not loaded' );
            $session->data();
            ok( $session->is_loaded(), 'session is loaded' );
        };

        subtest is_saved => sub{
            my $session = $starch->session();
            ok( (!$session->is_saved()), 'session is not saved' );
            $session->force_save();
            ok( $session->is_saved(), 'session is saved' );
        };

        subtest save => sub{
            my $session1 = $starch->session();

            $session1->data->{foo} = 789;
            my $session2 = $starch->session( $session1->id() );
            is( $session2->data->{foo}, undef, 'new session did not receive data from old' );

            is( $session1->is_dirty(), 1, 'is dirty before save' );
            $session1->save();
            is( $session1->is_dirty(), 0, 'is not dirty after save' );
            $session2 = $starch->session( $session1->id() );
            is( $session2->data->{foo}, 789, 'new session did receive data from old' );
        };

        subtest force_save => sub{
            my $session = $starch->session();

            $session->data->{foo} = 931;
            $session->save();

            $session = $starch->session( $session->id() );
            $session->data();

            $starch->session( $session->id() )->delete();

            $session->save();
            is(
                $starch->session( $session->id() )->data->{foo},
                undef,
                'save did not save',
            );

            $session->force_save();
            is(
                $starch->session( $session->id() )->data->{foo},
                931,
                'force_save did save',
            );
        };

        subtest reload => sub{
            my $session = $starch->session();
            is( exception { $session->reload() }, undef, 'reloading a non-dirty session did not fail' );
            $session->data->{foo} = 2;
            like( exception { $session->reload() }, qr{dirty}, 'reloading a dirty session failed' );
        };

        subtest force_reload => sub{
            my $session1 = $starch->session();
            $session1->data->{foo} = 91;
            $session1->save();
            my $session2 = $starch->session( $session1->id() );
            $session2->data->{foo} = 19;
            $session2->save();
            $session1->reload();
            is( $session1->data->{foo}, 19, 'reload worked' );
        };

        subtest mark_clean => sub{
            my $session = $starch->session();
            $session->data->{foo} = 6934;
            is( $session->is_dirty(), 1, 'is dirty' );
            $session->mark_clean();
            is( $session->is_dirty(), 0, 'is clean' );
            is( $session->data->{foo}, 6934, 'data is intact' );
        };

        subtest rollback => sub{
            my $session = $starch->session();
            $session->data->{foo} = 6934;
            is( $session->is_dirty(), 1, 'is dirty' );
            $session->rollback();
            is( $session->is_dirty(), 0, 'is clean' );
            is( $session->data->{foo}, undef, 'data is rolled back' );

            $session->data->{foo} = 23;
            $session->mark_clean();
            $session->data->{foo} = 95;
            $session->rollback();
            is( $session->data->{foo}, 23, 'rollback to previous mark_clean' );
        };

        subtest delete => sub{
            my $session = $starch->session();
            like( exception { $session->delete() }, qr{stored}, 'calling delete on un-stored session fails' );
            $session->force_save();
            is( exception { $session->delete() }, undef, 'deleting a stored session does not fail' );
        };

        subtest force_delete => sub{
            my $session = $starch->session();
            $session->data->{foo} = 39;
            $session->save();

            $session = $starch->session( $session->id() );
            is( $session->data->{foo}, 39, 'session persists' );

            $session->delete();
            $session = $starch->session( $session->id() );
            is( $session->data->{foo}, undef, 'session was deleted' );
        };

        subtest set_expires => sub{
            my $session = $starch->session();
            is( $session->expires(), $starch->expires(), 'double check a new session gets the global expires' );
            $session->set_expires( 111 );
            $session->save();
            $session = $starch->session( $session->id() );
            is( $session->expires(), 111, 'custom expires was saved' );
        };

        subtest hash_seed => sub{
            my $session = $starch->session();
            isnt( $session->hash_seed(), $session->hash_seed(), 'two hash seeds are not the same' );
        };

        subtest generate_id => sub{
            my $session = $starch->session();

            isnt(
                $session->generate_id(),
                $session->generate_id(),
                'two generated ids are not the same',
            );
        };

        subtest reset_id => sub{
            my $session = $starch->session();

            $session->data->{foo} = 54;
            ok( $session->is_dirty(), 'session is dirty before save' );
            $session->save();
            ok( (!$session->is_dirty()), 'session is not dirty after save' );
            ok( $session->is_saved(), 'session is marked saved after save' );

            my $old_id = $session->id();
            $session->reset_id();
            ok( (!$session->is_saved()), 'session is not marked saved after reset_id' );
            ok( $session->is_dirty(), 'session is marked dirty after reset_id' );
            isnt( $session->id(), $old_id, 'session has new id after reset_id' );
            $session->save();

            my $old_session = $starch->session( $old_id );
            is( $old_session->data->{foo}, undef, 'old session data was deleted' );
        };

        subtest clone_data => sub{
            my $session = $starch->session();

            my $old_data = { foo=>32, bar=>[1,2,3] };
            my $new_data = $session->clone_data( $old_data );

            is_deeply( $new_data, $old_data, 'cloned data matches source data' );

            isnt( "$old_data->{bar}", "$new_data->{bar}", 'clone data structure has different reference' );
        };
    };

    return;
}

=head2 test_store

Tests the L<Starch::Store>.

=cut

sub test_store {
    my ($self) = @_;

    my $starch = $self->new_manager();
    my $store = $starch->store();

    subtest 'core tests for ' . ref($store) => sub{

        subtest 'set, get, and remove' => sub{
            my $key = 'starch-test-key';
            $store->remove( $key );

            is( $store->get( $key ), undef, 'no data before set' );

            $store->set( $key, {foo=>6}, 10 );
            is( $store->get( $key )->{foo}, 6, 'has data after set' );

            $store->remove( $key );

            is( $store->get( $key ), undef, 'no data after remove' );
        };

        subtest max_expires => sub{
            my $starch = $self->new_manager(
                expires => 89,
            );
            is( $starch->store->max_expires(), undef, 'store max_expires left at undef' );

            $starch = $self->new_manager(
                store=>{ class=>'::Memory', max_expires=>67 },
                expires => 89,
            );
            is( $starch->store->max_expires(), 67, 'store max_expires explicitly set' );
        };
    };

    return;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

