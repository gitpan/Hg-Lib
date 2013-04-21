package Server::Capability::GetEncoding;

use Moo::Role;

requires 'encoding';

around _build_capabilities => sub {

    my ( $orig, $self ) = ( shift, shift );

    my $capabilities = $self->$orig( @_ );

    $capabilities->{getencoding} = 1;

    return $capabilities

};

sub getencoding {

    my $self = shift;

    $self->write_chunk( 'r', $self->encoding );

}

1;
