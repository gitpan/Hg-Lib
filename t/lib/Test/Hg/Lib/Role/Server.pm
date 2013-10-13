#! perl

package Test::Hg::Lib::Role::Server;

use t::common;

use Try::Tiny;

use Test::Roo::Role;
use Test::Fatal;

use Types::Standard qw[ ArrayRef Str ];

use Capture::Tiny 'capture';
use YAML::Tiny;

use Hg::Lib::Server;
use Hg::Lib::Exception -aliases;

has server => (
    is      => 'lazy',
    clearer => 1,
    builder => sub {
        Hg::Lib::Server->new(
            hg      => fake_hg,
            args    => 'full',
            connect => 1,
        );
    } );

has stop_error => (
    is        => 'rw',
    predicate => 1,
    clearer => 1,
    isa       => ArrayRef,
);

sub start_server {

    $_[0]->server;

}

sub stop_server {

    my $self = shift;

    my $e = exception { $self->server->close };

    try {
        if ( $self->has_stop_error ) {

            my ( $exp_exception, $exp_message ) = @{ $self->stop_error };

            isa_ok( $e, $exp_exception, $exp_exception )
              or die( "bailing out" );
            like( $e, $exp_message, 'message' );
        }

        else {

            is( $e, undef, "successful server exit" );

        }
    }
    catch {

        diag $_;

    }
    finally {

        $self->clear_server;
	$self->clear_stop_error;

    };

}

sub run {

    my $self = shift;
    my @args = @_;

    return capture { $self->server->runcommand( @args ) };
}

sub run_yaml {

    my $self = shift;

    my ( $stdout, $stderr, $exit ) = $self->run( @_ );

    return length( $stdout ) ? YAML::Tiny->read_string( $stdout ) : undef,
      length( $stderr )      ? YAML::Tiny->read_string( $stderr ) : undef,
      $exit;
}

1;

