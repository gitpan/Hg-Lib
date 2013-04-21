package Server::Full;

use Moo;

extends 'Server::Base';

# get dispatch
with 'Server::Commands';

with 'Server::Capability::GetEncoding', 'Server::Capability::RunCommand';


1;
