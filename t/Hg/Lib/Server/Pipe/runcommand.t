#! perl

package Pipe::RunCommand;

use 5.10.1;

use strict;
use warnings;

use t::common;

use Test::Roo;
use Test::Fatal;

with 'Test::Hg::Lib::Role::Server';

use Hg::Lib::Exception -aliases;

before each_test => sub { $_[0]->start_server };
after  each_test => sub { $_[0]->stop_server  };

# test the default error channel handler
test 'echo error' => sub {

    my $self   = shift;

    {
        my ( $out, $err, $exit ) = $self->run_yaml( ['echo_error'] );

        is_deeply(
            $err->[0],
            {
                cmd  => 'echo_error',
                args => []
            },
            "echo_error, no args"
        );
    }

    {
        my ( $out, $err, $exit )
          = $self->run_yaml( [ 'echo_error', '-a' ] );

        is_deeply(
            $err->[0],
            {
                cmd  => 'echo_error',
                args => ['-a']
            },
            "echo_error, args: -a"
        );
    }

};

# test the default output channel handler
test 'echo_output' => sub {

    my $self   = shift;

    my ( $out, $err, $exit )
      = $self->run_yaml( [ 'echo_output', '--a', 3 ] );

    is_deeply(
        $out->[0],
        {
            cmd  => 'echo_output',
            args => [ '--a', 3 ]
        },
        "echo_output, args: --a 3"
    );

};

test 'failed' => sub {

    my $self   = shift;

    my ( $out, $err, $exit ) =  $self->run( [ 'fail' ] );

    is ( $out, '', 'no output on failure' );
    is ( $err, 'failed!', 'error output on failure' );
    is ( $exit, 193, 'error code' );
};

test 'no L handler' => sub {

    my $self   = shift;

    my ( $stdout, $stderr, $exit );

    my $e = exception {
	( $stdout, $stderr, $exit ) = $self->run( ['read_line'] )
    };

    isa_ok( $e, EPipe, 'EPipe' );
    like( $e, qr/unexpected data .* channel L/, 'message' );

    $self->stop_error( [ EPipe, qr/unexpected termination of server/ ] );

};

test 'L handler' => sub {

    my $self   = shift;

    my $buffer;

    my $handle_L  = sub {
        my $length = shift;

        state $i = 5;

	is( $length, 4096, "requested length\n" );

	if ( $i == 5 ) {
	    is( $buffer, 'Please enter something', 'initial output channel' );
	    undef $buffer;
	}
	else {
	    is( $buffer, undef, 'subsequent output channel' );
	}

        return $i ? sprintf( "%03d\n", $i-- ) : '';
    };

    # my $buffer = shift;
    my $handle_o  = sub { $buffer .= $_[0]  };

    my $e = exception {
        $self->server->runcommand(
            [ 'read_line' ],
            inchannels  => { L => $handle_L },
            outchannels => { o => $handle_o },
        );
    };

    is( $e, undef, 'no exception' )
	or do {
	    diag "bailing";
	    return };

    is( $buffer, "001\n002\n003\n004\n005\n", 'returned message' );

};

run_me;
done_testing;
