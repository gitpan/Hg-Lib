package Server::Capability::RunCommand;

use Carp;

use Moo::Role;

requires 'dispatch';

around _build_capabilities => sub {

    my ( $orig, $self ) = ( shift, shift );

    my $capabilities = $self->$orig( @_ );

    $capabilities->{runcommand} = 1;

    return $capabilities;

};

sub runcommand {

    my $self = shift;

    my ( $cmd, @args ) = split( "\0", $self->read_chunk );

    my $mth = $self->dispatch( $cmd );

    croak( "unknown command: $cmd\n" )
      if !defined $mth;

    my $ret = $mth->( $self, $cmd, @args );

    $self->write_chunk( 'r', pack( 'l>', $ret ) );

    return;
}

1;


