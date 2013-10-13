#! perl

package Test::Hg::Lib::Client;

use base 'Test::Class';

use t::common;

use Test::More;
use Test::Fatal;

use Hg::Lib::Client;
use Hg::Lib::Exception -aliases;

sub start_client : Test(setup) {

    shift->{client} = Hg::Lib::Client->new(
        hg   => fake_hg,
        args => 'full'
    );
}

sub stop_server : Test(teardown => no_plan) {

    my $self = shift;

    my $e = exception { delete $self->{client} };

    if ( defined $self->{stop_error} ) {

	my ( $exp_exception, $exp_message ) = @{$self->{stop_error}};

	__PACKAGE__->num_method_tests( 'stop_server', 2 );

	isa_ok( $e, $exp_exception, $exp_exception );
	like( $e, $exp_message, 'message' );
    }

    else {

	__PACKAGE__->num_method_tests( 'stop_server', 1 );

	is ( $e, undef, "successful server exit" );
    }

}

1;

