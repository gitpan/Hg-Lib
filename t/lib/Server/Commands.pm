package Server::Commands;

use Moo::Role;

my %commands = (

    ls => sub {
	my $server = shift;
	my $dir = qx{ls};
	chomp $dir;
	! $server->write_chunk( 'o', $dir );
    }
);

sub dispatch {

    print STDERR "DISPATCHED\n";

    my $cmd = $_[1];
    chomp $cmd;
    return $commands{ $cmd };

}

1;



