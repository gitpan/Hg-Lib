#!perl

use strict;
use warnings;

use t::common;

use Test::More;
use Test::Fatal;

use Hg::Lib::Server;
use Hg::Lib::Exception -aliases;

sub new { Hg::Lib::Server->new( hg => fake_hg, connect => 1, @_ ) }

is( new( args => 'basic' )->getencoding, 'utf-8', 'default encoding' );

is( new( args => 'basic', encoding => 'foo' )->getencoding,
    'foo', 'requested encoding' );

subtest 'incorrect encoding' => sub {

    my $e = exception { new( encoding => 'foo',
			     args => [ qw( bad_bad_encoding ) ] ) };

    isa_ok( $e, EHandshake, 'EHandshake' );
    isa_ok( $e->previous_exception, EEncoding, 'EEncoding' );
    like( $e, qr/incorrect encoding/, 'message' );
};


done_testing;


