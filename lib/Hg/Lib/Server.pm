package Hg::Lib::Server;

use 5.10.1;

use Carp;

use System::Command;
use Params::Validate ':all';

# for perl 5.10.1
use FileHandle;

use Moo;
use MooX::Types::MooseLike::Base qw[ :all ];

use Try::Tiny;

use constant forceArray => sub { 'ARRAY' eq ref $_[0] ? $_[0] : [ $_[0] ] };

with 'MooX::Attributes::Shadow::Role';

shadowable_attrs( qw[ hg args path configs encoding env ] );

# path to hg executable; allow multiple components
has hg => (
    is      => 'ro',
    default => 'hg',
    coerce  => forceArray,
    isa     => ArrayRef [Str],
);

# arguments to hg
has args => (
    is      => 'ro',
    coerce  => forceArray,
    isa     => ArrayRef [Str],
    default => sub { [] },
);

has path => (
    is        => 'ro',
    predicate => 1,
);

has configs => (
    is      => 'ro',
    coerce  => forceArray,
    isa     => ArrayRef [Str],
    default => sub { [] },
);

# default encoding; set to that returned by the hg hello response
has encoding => (
    is        => 'rwp',
    predicate => 1,
    clearer   => '_clear_encoding',
);

has env => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

# the actual pipe object.  the pipe should be lazily created when any
# handled method is used.  $server->_get_hello *must* be called after
# pipe creation; trigger will do that.  however, trigger is not called
# when default is used, only when attribute is set. so, have
# default call $server->open which calls setter.

has _pipe => (

    is        => 'rw',
	      init_arg => undef,
    lazy => 1,
    predicate => 1,
    trigger   => sub { $_[0]->_get_hello },
    handles  => [qw[ stdin stdout stderr pid close is_terminated ]],
    default => sub { $_[0]->open },
);


has connect => (

    is      => 'ro',
    default => 0,

);

# constructed command line; does not include environment variables
has _cmdline => (
    is       => 'lazy',
    init_arg => undef,
    builder  => sub {

        my $self = shift;

        my @cmd = (
            @{ $self->hg },
            qw[ --config ui.interactive=True
              serve
              --cmdserver pipe
              ],
        );

        push @cmd, '-R', $self->path if $self->has_path;

        push @cmd, map { ( '--config' => $_ ) } @{ $self->configs };

        push @cmd, @{ $self->args };

        return \@cmd;
    },

);


has capabilities => (
    is        => 'rwp',
    predicate => 1,
    init_arg  => undef,
);

sub BUILD {

    my $self = shift;

    $self->open if $self->connect;

}

sub DEMOLISH {

    my $self = shift;

    $self->close if $self->_has_pipe;

}

sub open {

    my $self = shift;

    my $env = $self->env;

    $env->{HGPLAIN}    = 1;
    $env->{HGENCODING} = $self->encoding
      if $self->has_encoding;

    my $pipe
      = System::Command->new( @{ $self->_cmdline }, { env => $self->env } );
    $self->_pipe( $pipe );

    return $pipe;
}

sub read {

    my $self = shift;

    # use aliased data in @_ to prevent copying
    return $self->stdout->sysread( @_ );
}

# always use aliased $_[0] as buffer to prevent copying
# call as get_chunk( $buf )
sub get_chunk {

    my $self = shift;

    # catch pipe errors from child
    local $SIG{'PIPE'} = sub { croak( "SIGPIPE on read from server\n" ) };

    my $nr = $self->read( $_[0], 5 );
    croak( "error reading chunk header from server: $!\n" )
      unless defined $nr;

    $nr > 0
      or croak( "unexpected end-of-file getting chunk header from server\n" );

    my ( $ch, $len ) = unpack( 'A[1] l>', $_[0] );

    if ( $ch =~ /IL/ ) {

        croak(
            "get_chunk called incorrectly called in scalar context for channel $ch\n"
        ) unless wantarray();

        return $ch, $len;
    }

    else {

        $self->read( $_[0], $len ) == $len
          or croak(
            "unexpected end-of-file reading $len bytes from server channel $ch\n"
          );

        return $ch;
    }

}

# call as $self->write( $buf, [ $len ] )
sub write {

    my $self = shift;
    my $len = @_ > 1 ? $_[1] : length( $_[0] );
    $self->stdin->syswrite( $_[0], $len ) == $len
      or croak( "error writing $len bytes to server\n" );
}

sub writeblock {

    my $self = shift;

    $self->write( pack( "N/a*", $_[0] ) );
}

sub _get_hello {

    my $self = shift;

    my $buf;
    my $ch = $self->get_chunk( $buf );

    croak( "corrupt or incomplete hello message from server\n" )
      unless $ch eq 'o' && length $buf;

    my $requested_encoding = $self->has_encoding ? $self->encoding : undef;
    $self->_clear_encoding;

    for my $item ( split( "\n", $buf ) ) {

        my ( $field, $value ) = $item =~ /([a-z0-9]+):\s*(.*)/;

        if ( $field eq 'capabilities' ) {

            $self->_set_capabilities(
                { map { $_ => 1 } split( ' ', $value ) } );
        }

        elsif ( $field eq 'encoding' ) {

            croak( sprintf "requested encoding of %s; got %s",
                $requested_encoding, $value )
              if defined $requested_encoding && $requested_encoding ne $value;

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

__END__

=pod

=head1 NAME

Hg::Lib::Server

=head1 VERSION

version 0.01_03

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Diab Jerius E<lt>djerius@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
