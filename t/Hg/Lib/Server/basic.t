#!perl

use strict;
use warnings;

use t::common;

use Test::More;
use Test::Fatal;

use Hg::Lib::Server;
use Hg::Lib::Exception -aliases;

sub new { Hg::Lib::Server->new( hg => fake_hg, connect => 1, @_ ) }

is(
   exception { new( args => [ qw( basic ) ] ) },
   undef,
   'hello, no args'
);

subtest 'bad hello channel' => sub {

    my $e = exception { new( args => [ qw( bad_hello_chan ) ] ) };

    isa_ok( $e, EHandshake, 'EHandshake' );
    isa_ok( $e->previous_exception, EPipe, 'EPipe' );
    like( $e, qr/incomplete hello message .* channel = e/, 'message' );
};

subtest 'bad hello length' => sub {

    my $e = exception { new( args => [ qw( bad_hello_len ) ] ) };

    isa_ok( $e, EHandshake, 'EHandshake' );
    isa_ok( $e->previous_exception, EPipe, 'EPipe' );
    like( $e, qr/incomplete hello message .* length = 0/, 'message' );

};

subtest 'missing capabilities' => sub {

    my $e = exception { new( args => [ qw( bad_hello_no_capabilities ) ] ) };

    isa_ok( $e, EHandshake, 'EHandshake' );
    isa_ok( $e->previous_exception, ECapability, 'ECapability' );
    like( $e, qr/did not provide capabilities/, 'message' );
};

subtest 'no runcommand capability' => sub {

    my $e = exception { new( args => [ qw( bad_hello_no_runcommand ) ] ) };

    isa_ok( $e, EHandshake, 'EHandshake' );
    isa_ok( $e->previous_exception, ECapability, 'ECapability' );
    like( $e, qr/missing runcommand capability/, 'message' );
};

subtest 'missing encoding' => sub {

    my $e = exception { new( args => [ qw( bad_hello_no_encoding ) ] ) };

    isa_ok( $e, EHandshake, 'EHandshake' );
    isa_ok( $e->previous_exception, EEncoding, 'EEncoding' );
    like( $e, qr/did not provide encoding/, 'message' );
};


done_testing;


