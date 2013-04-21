package Hg::Lib::Server;

use 5.10.1;

use Carp;

use Params::Validate ':all';

use Moo;
use MooX::Types::MooseLike::Base qw[ :all ];

use Hg::Lib::Server::Pipe;

Hg::Lib::Server::Pipe->shadow_attrs;

has server => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    handles  => [qw[ get_chunk write writeblock ]],
    default  => sub {
        Hg::Lib::Server::Pipe->new(
            Hg::Lib::Server::Pipe->xtract_attrs( $_[0] ) );
    },
);

has capabilities => (
    is        => 'rwp',
    predicate => 1,
    init_arg  => undef,
);

has encoding => (
    is        => 'rwp',
    predicate => 1,
    init_arg  => undef,
);


sub BUILD {

    $_[0]->_get_hello;
}

sub _get_hello {

    my $self = shift;

    my $buf;
    my $ch = $self->get_chunk( $buf );

    croak( "corrupt or incomplete hello message from server\n" )
      unless $ch eq 'o' && length $buf;

    for my $item ( split( "\n", $buf ) ) {

        my ( $field, $value ) = $item =~ /([a-z0-9]+):\s*(.*)/;

        if ( $field eq 'capabilities' ) {

            $self->_set_capabilities(
                { map { $_ => 1 } split( ' ', $value ) } );
        }

        elsif ( $field eq 'encoding' ) {

            $self->_set_encoding( $value );

        }

        # ignore anything else 'cause we don't know what it means

    }

    # make sure hello message meets minimum standards
    croak( "server did not provide capabilities?\n" )
      unless $self->has_capabilities;

    croak( "server is missing runcommand capability\n" )
      unless exists $self->capabilities->{runcommand};

    croak( "server did not provide encoding?\n" )
      unless $self->has_encoding;

    return;
}

sub getencoding {

    my $self = shift;

    $self->write( "getencoding\n" );

    my $buffer;
    my ( $ch, $len ) = $self->get_chunk( $buffer );

    croak( "unexpected return message for getencoding on channel $ch\n" )
      unless $ch eq 'r' && length( $buffer );

    return $buffer;

}

# $server->runcommand( args => [ $command, @args ],
#                      inchannels => \%callbacks,
#                      outchannels => \%callbacks )
sub runcommand {

    my $self = shift;

    my $opts = validate(
        @_,
        {
            inchannels => {
                type    => HASHREF,
                default => {}
            },
            outchannels => {
                type    => HASHREF,
                default => {}
            },
            args => {
                type    => ARRAYREF,
                default => {}
            },
        } );

    $self->write( "runcommand\n" );
    $self->writeblock( join( "\0", @{ $opts->{args} } ) );

    # read from server until a return channel is specified
    my $buffer;
    while ( 1 ) {

        my ( $ch, $len ) = $self->get_chunk( $buffer );

        for ( $ch ) {

            when ( $opts->{inchannels} ) {

                $self->writeblock( $opts->{inchannels}{$ch}->( $buffer ) );
            }

            when ( $opts->{outchannels} ) {

                $opts->{outchannels}{$ch}->( $buffer );
            }


            when ( 'r' ) {

                state $length_exp = length( pack( 'l>', 0 ) );
                croak( sprintf "incorrect message length (got %d, expected %d)",
                    length( $buffer ), $length_exp )
                  if length( $buffer ) != $length_exp;

                return unpack( 'l>', $buffer );
            }

            when ( /[[:upper:]]/ ) {

                croak( "unexpected data on required channel $ch\n" );
            }

        }


    }

}

1;
