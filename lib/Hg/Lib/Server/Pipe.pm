package Hg::Lib::Server::Pipe;

use 5.10.1;

use Carp;

use IO::Select;

# for perl 5.10.1
use FileHandle;

use System::Command;
use Try::Tiny;
use Types::Standard -all;
use Type::Params;

use Hg::Lib::Utils 'find_hg';

use Hg::Lib::Exception -aliases;

use Hg::Lib::Types '-all';

use Moo;

no if $] >= 5.018, 'warnings', "experimental::smartmatch";

with 'MooX::Attributes::Shadow::Role';

shadowable_attrs( qw[ hg args path configs encoding env timeout ] );

# path to hg executable; allow multiple components
has hg => (
    is      => 'ro',
    default => sub { find_hg() },
    isa     => StrList,
    coerce  => StrList->coercion,
);

# arguments to hg
has args => (
    is      => 'ro',
    isa     => StrList,
    coerce  => StrList->coercion,
    default => sub { [] },
);

has path => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);

has configs => (
    is      => 'ro',
    isa     => StrList,
    coerce  => StrList->coercion,
    default => sub { [] },
);

# used for optional initial encoding; set to encoding returned in
# server's hello message
has encoding => (
    is        => 'rwp',
    clearer   => 1,
    predicate => 1,
    isa       => Str,
);

# what the server claims i can do
has capabilities => (
    is        => 'rwp',
    predicate => 1,
    init_arg  => undef,
);

# constructed command line; does not include environment variables
has cmdline => (
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

# passed command environment
has env => (

    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },

);

# Pipe object
has pipe => (
    is        => 'rwp',
    init_arg  => undef,
    handles   => [qw[ stdin stdout stderr ]],
    clearer   => 1,
    predicate => 1,
);

has timeout => (
    is      => 'rw',
    isa     => Num,
    default => 5,
);

sub BUILD {

    my $self = shift;

    my $env = $self->env;
    $env->{HGPLAIN}    = 1;
    $env->{HGENCODING} = $self->encoding
      if $self->has_encoding;

    $self->_set_pipe(
        System::Command->new( @{ $self->cmdline }, { env => $self->env } ) );
    $self->stderr->blocking( 0 );

    # get hello message; on failure make sure we pick up
    # any output on stderr vi $self->close
    try {

        $self->_get_hello;

    }
    catch {

        local $@ = $_;

        try {
	    my $e = $@;

            $self->close;

	    # make sure we rethrow the original error
	    die $e;

        }
        catch {

            local $@ = $_;

	    if ( /no Mercurial repository here/ ) {

		ENoRepo->throw( "no repository?" );

	    }
	    else {
		EHandshake->throw( "error in handshake with server" );
	    }
        };
    };

    return;
}


sub DEMOLISH {

    local $@;
    $_[0]->close;

}

sub close {

    my $self = shift;

    return unless $self->has_pipe;

    # whatever happens, $self->pipe must die!
    my $pipe = $self->pipe;
    $self->clear_pipe;

    # this signals hg to quit.
    $pipe->stdin->close;

    my $stderr
      = IO::Select->new( $pipe->stderr )->can_read( $self->timeout )
      ? join( '', $pipe->stderr->getlines )
      : '';

    chomp $stderr;

    $pipe->close;

    if ( $pipe->exit ) {
        EPipeTerminated->throw(
            join( "\n",
                "unexpected termination of server: exit code: " . $pipe->exit,
                "server stderr: $stderr", '' ) );
    }

    EPipeStderr->throw( "server stderr: $stderr" ) if length( $stderr );

    return;
}

sub _read {

    my $self = shift;

    # note that can_read returns an fh on its EOF as well as when it
    # is available for reading.
    EPipeTimeout->throw( "timed out waiting for data from server" )
      unless IO::Select->new( $self->stdout )->can_read( $self->timeout );

    # use aliased data in @_ to prevent copying
    return $self->stdout->sysread( @_ );
}

# always use aliased $_[0] as buffer to prevent copying
# call as get_chunk( $buf )
sub get_chunk {

    my $self = shift;

    # catch pipe errors from child
    local $SIG{'PIPE'} = sub {
        EPipe->throw( "SIGPIPE on read from server" );
    };

    my $nr = $self->_read( $_[0], 5 );
    EPipe->throw( "error reading chunk header from server: $!" )
      unless defined $nr;

    $nr > 0
      or EPipeEOF->throw(
        "unexpected end-of-file getting chunk header from server" );

    my ( $ch, $len ) = unpack( 'A[1] l>', $_[0] );

    if ( $ch =~ /[IL]/ ) {

        EPipe->throw(
            "get_chunk called incorrectly called in scalar context for channel $ch"
        ) unless wantarray();

        return $ch, $len;
    }

    else {

        if ( $len ) {

            my $nr = $self->_read( $_[0], $len );

            $nr == $len
              or EPipeEOF->throw(
                "unexpected end-of-file on channel $ch; expected $len bytes, got $nr"
              );
        }
        else {
            $_[0] = '';
        }

        return $ch;
    }

}

# call as $self->write( $buf, [ $len ] )
sub write {

    my $self = shift;
    my $len = @_ > 1 ? $_[1] : length( $_[0] );
    $self->stdin->syswrite( $_[0], $len ) == $len
      or EPipe->throw( "error writing $len bytes to server" );
}

sub writeblock {

    my $self = shift;

    $self->write( pack( "N/a*", $_[0] ) );
}

sub _get_hello {

    my $self = shift;

    my $buf;
    my $ch = $self->get_chunk( $buf );

    EPipe->throw(
        "corrupt or incomplete hello message from server: channel = $ch; length = "
          . length $buf )
      unless $ch eq 'o' && length $buf;

    my $requested_encoding = $self->has_encoding ? $self->encoding : undef;
    $self->clear_encoding;

    for my $item ( split( "\n", $buf ) ) {

        my ( $field, $value ) = $item =~ /([a-z0-9]+):\s*(.*)/;

        if ( $field eq 'capabilities' ) {

            $self->_set_capabilities(
                { map { $_ => 1 } split( ' ', $value ) } );
        }

        elsif ( $field eq 'encoding' ) {

            EEncoding->throw(
                "incorrect encoding returned: requested '$requested_encoding', got '$value'"
            ) if defined $requested_encoding && $requested_encoding ne $value;

            $self->_set_encoding( $value );

        }

        # ignore anything else 'cause we don't know what it means

    }

    # make sure hello message meets minimum standards
    ECapability->throw( "server did not provide capabilities?" )
      unless $self->has_capabilities;

    ECapability->throw( "server is missing runcommand capability" )
      unless exists $self->capabilities->{runcommand};

    EEncoding->throw( "server did not provide encoding?" )
      unless $self->has_encoding;

    return;
}

sub getencoding {

    my $self = shift;

    $self->write( "getencoding\n" );

    my $buffer;
    my ( $ch, $len ) = $self->get_chunk( $buffer );

    EPipe->throw( "unexpected return message for getencoding on channel $ch\n" )
      unless $ch eq 'r' && length( $buffer );

    return $buffer;

}

# $server->runcommand( [ $command, @args ],
#                      inchannels => \%callbacks,
#                      outchannels => \%callbacks )
sub runcommand {

    my $self = shift;

    # constraint check
    state $check = compile(
        ArrayRef [Str],
        slurpy Dict [
            inchannels  => Optional [ HashRef [CodeRef] ],
            outchannels => Optional [ HashRef [CodeRef] ],
        ] );

    state $outchannels = {
        o => sub { print STDOUT @_ },
        e => sub { print STDERR @_ },
    };

    my ( $args, $opts ) = $check->( @_ );

    $opts->{inchannels}  //= {};
    $opts->{outchannels} //= $outchannels;

    $self->write( "runcommand\n" );
    $self->writeblock( join( "\0", @$args ) );

    # read from server until a return channel is specified
    my $buffer;
    while ( 1 ) {

        my ( $ch, $len ) = $self->get_chunk( $buffer );

        for ( $ch ) {

            when ( $opts->{inchannels} ) {

                $self->writeblock( $opts->{inchannels}{$ch}->( $len ) );
            }

            when ( $opts->{outchannels} ) {

                $opts->{outchannels}{$ch}->( $buffer );
            }

            when ( 'r' ) {

                state $length_exp = length( pack( 'l>', 0 ) );
                EPipe->throw(
                    sprintf "incorrect message length (got %d, expected %d)",
                    length( $buffer ), $length_exp )
                  if length( $buffer ) != $length_exp;

                return unpack( 'l>', $buffer );
            }

            when ( /[[:upper:]]/ ) {

                EPipe->throw( "unexpected data on required channel $ch\n" );
            }
        }
    }
    return;
}

1;

__END__

=pod

=head1 NAME

Hg::Lib::Server::Pipe

=head1 VERSION

version 0.01_05

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Diab Jerius E<lt>djerius@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
