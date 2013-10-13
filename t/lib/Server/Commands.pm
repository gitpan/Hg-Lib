package Server::Commands;

use Moo::Role;
use YAML::Tiny;

my %commands = (

    ls => sub {
        my $server = shift;
        my $dir    = qx{ls};
        chomp $dir;
        !$server->write_chunk( 'o', $dir );
    },

    fail => sub {

        my ( $server, $cmd, @args ) = @_;

        $server->write_chunk( 'e', 'failed!' );
	return 193;
    },

    echo_error => sub {
        my ( $server, $cmd, @args ) = @_;

        my $yaml = YAML::Tiny->new;

        $yaml->[0] = { cmd => $cmd, args => \@args };

        !$server->write_chunk( 'e', $yaml->write_string );
    },

    echo_output => sub {
        my ( $server, $cmd, @args ) = @_;

        my $yaml = YAML::Tiny->new;

        $yaml->[0] = { cmd => $cmd, args => \@args };

        !$server->write_chunk( 'o', $yaml->write_string );
    },

    read_line => sub {

        my $server = shift;
        my ( $nr, $buf, @buf );

	$server->write_chunk( 'o', 'Please enter something' );

        do {
            $server->write( pack( 'A[1] N', 'L', 4096 ) );
            $server->read_chunk( $buf );
	    $nr = length $buf;
            unshift @buf, $buf if $nr;
        } while $nr;

        return !$server->write_chunk( 'o', join( '', @buf ) );
      }


);

sub dispatch {

    my $cmd = $_[1];
    chomp $cmd;
    return $commands{$cmd};

}

1;
