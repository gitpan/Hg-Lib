package Server::Base;

use Moo;
use Sub::Quote qw[ quote_sub ];
use IO::Handle;
use Carp;

has capabilities => (
    is      => 'lazy',
    builder => sub { return {} },
);


has input => (
    is       => 'ro',
    init_arg => undef,
    default  => quote_sub q{ \*STDIN },
);

has output => (
    is       => 'ro',
    init_arg => undef,
    default  => quote_sub q{ \*STDOUT },
);

has encoding => (
    is        => 'rw',
    predicate => 1,
    clearer   => 1,
    default   => quote_sub q{ $ENV{HGENCODING} // 'utf-8' }
);

sub read {

    my ( $self, $size ) = ( shift, shift );

    my $buf;

    if ( $size ) {

        my $r = $self->input->read( @_ ? $_[-1] : $buf, $size );
        croak( "EOF\n" ) unless defined $r && $size == $r;

    }

    else {

        ( @_ ? $_[-1] : $buf ) = '';

    }

    return $buf unless @_;
    return;
}

sub read_chunk {

    my $self = shift;

    my $buf;

    $self->read( 4, $buf );

    my $len = unpack( 'N', $buf );

    return $self->read( $len, @_ );
}

sub write_chunk {

    my $self = shift;

    # my ( $channel, $data ) = @_;

    return  defined $self->output->syswrite( pack( 'A[1] N/A*', @_ ) );
}

sub say_hello {

    my $self = shift;

    my @capabilities = keys %{ $self->capabilities };

    $self->write_chunk(
        'o',
        join( "\n",
            @capabilities
            ? ( join( ' ', 'capabilities:', @capabilities ) )
            : (),
            $self->has_encoding ? 'encoding: ' . $self->encoding : (),
        ) );
}

sub serve {

    my $self = shift;

    $self->say_hello;

    while ( my $cmd = $self->input->getline ) {

        chomp $cmd;

        if ( $self->capabilities->{$cmd} ) {

            my $mth = $self->can( $cmd )
              or croak(
                "internal error; should be able to perform capability: $cmd\n"
              );

            $self->$mth;

        }

        else {

            croak( "unknown command: $cmd\n" );

        }

    }

}

sub DEMOLISH { }

1;
