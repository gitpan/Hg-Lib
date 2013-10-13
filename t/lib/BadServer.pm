use lib 't';

########################################################################

package BadServer::Hello::Chan;

use Moo;

extends 'Server::Base';

sub say_hello {

    $_[0]->write_chunk( 'e', '' );

}

########################################################################

package BadServer::Hello::Len;

use Moo;

extends 'Server::Base';

sub say_hello {

    $_[0]->write_chunk( 'o', '' );

}

########################################################################

package BadServer::NoCapabilities;

use Moo;

extends 'Server::Base';

########################################################################

package BadServer::NoRunCommand;

use Moo;

extends 'Server::Base';
with 'Server::Capability::GetEncoding';

########################################################################

package BadServer::NoEncoding;

use Moo;

extends 'Server::Base';

sub dispatch{ return }

with 'Server::Capability::RunCommand';

sub BUILD {

    $_[0]->clear_encoding;

}

########################################################################

package BadServer::BadEncoding;

use Moo;

extends 'Server::Base';

sub dispatch{ return }

with 'Server::Capability::RunCommand';

sub BUILD {

    $_[0]->encoding( 'foo is king' );

}

########################################################################

package BadServer::FailWithStderr;

use Moo;

extends 'Server::Base';

sub dispatch{ return }

with 'Server::Capability::GetEncoding', 'Server::Capability::RunCommand';

after 'say_hello' => sub {

    print STDERR "Message from Server on STDERR\n";
    exit(1);

};

########################################################################

package BadServer::ExitWithStderr;

use Moo;

extends 'Server::Base';

sub dispatch{ return }

with 'Server::Capability::GetEncoding', 'Server::Capability::RunCommand';

after 'say_hello' => sub {

    print STDERR "Message from Server on STDERR\n";
};

########################################################################

1;

