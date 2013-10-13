#! perl

package Test::Hg::Lib::Server;

use base 'Test::Class';

use t::common;

use Capture::Tiny 'capture';
use YAML::Tiny;

use Test::More;
use Test::Fatal;

use Hg::Lib::Server;
use Hg::Lib::Exception -aliases;

sub start_server : Test(setup) {

    shift->{server} = Hg::Lib::Server->new(
        hg   => fake_hg,
        args => 'full'
    );
}

sub stop_server : Test(teardown => no_plan) {

    my $self = shift;

    my $e = exception { $self->{server}->close };

    if ( defined $self->{stop_error} ) {

	my ( $exp_exception, $exp_message ) = @{$self->{stop_error}};

	isa_ok( $e, $exp_exception, $exp_exception );
	like( $e, $exp_message, 'message' );
    }

    else {

	is ( $e, undef, "successful server exit" );

    }

}

sub run {

    my $self = shift;
    my @args = @_;

    my $server = $self->{server};

    return capture { $server->runcommand( @args ) };
}

sub run_yaml {

    my $self = shift;
    my @args = @_;

    my $server = $self->{server};

    my ( $stdout, $stderr, $exit ) = capture {
        $server->runcommand( @args );
    };

    return  length($stdout) ? YAML::Tiny->read_string( $stdout ) : undef ,
	    length($stderr) ? YAML::Tiny->read_string( $stderr ) : undef ,
	   $exit;

}

1;

