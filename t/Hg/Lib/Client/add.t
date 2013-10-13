#! perl


use Test::Roo;

use Test::Lib;
use Test::Fatal;

use Hg::Lib::Exception -aliases;

use Test::Hg::Lib::Exec;

with 'Test::Hg::Lib::Role::Client';
with 'Test::Hg::Lib::Role::BasicRepo';
with 'Test::Hg::Lib::Role::TempDir';

test add => sub {

    my $self = shift;

    my $res = $self->client->add( 'a' );

    is( $res->ret, 0, "add existing file" );

    my $status = xhg( 'status' );

    is_deeply(
        $status,
        {
            a => 'A',
            b => '?',
            c => '?'
        },
        'consistent status'
    );

};

test add_non_existent => sub {

    my $self = shift;

    my $e;

    isa_ok(
	   $e = exception { $self->client->add( 'a2' ); },
	   ECommand,
	   'exception thrown' );

    my $res = $e->result;

    ok( ! $res, "add non-existing file" );

    my $status = xhg( 'status' );

    is_deeply(
        $status,
        {
            a => '?',
            b => '?',
            c => '?'
        },
        'consistent status'
    );

};

run_me;
done_testing;
