package Server::Basic;

use Moo;

extends 'Server::Base';

sub dispatch { return }

with 'Server::Capability::GetEncoding', 'Server::Capability::RunCommand';


1;
