#!perl

use strict;
use warnings;

use t::common;

use Test::More;
use Test::Exception;

use Hg::Lib::Server;

sub fnew { Hg::Lib::Server->new( hg => fake_hg, @_ ) }

lives_ok { fnew( args => [ qw( wait ) ] ) } 'fake, no args';

throws_ok {

    my $server = fnew( args => [ qw( fail )  ] );

    # we have to wait a bit to make sure that the process actually
    # dies.
    for ( 0..10 ) {
	sleep 1;
	$server->is_terminated && die( "unexpected exit of child" );
    }


}  qr/unexpected end-of-file/, 'fake, fail';


subtest 'badlen' => sub {

    my $hg;
    lives_ok { $hg = fnew( args => [ qw(  badlen ) ] ) } 'open hg';


    throws_ok { $hg->get_chunk( my $buf ) } qr/end-of-file reading/, 'short data';

};


done_testing;


