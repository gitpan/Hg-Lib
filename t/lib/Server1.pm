use Server;
use lib 't';

########################################################################

package Server1;

use Moo;

extends 'Server';

with 'Server::Commands';

1;
