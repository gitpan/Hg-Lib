package Hg::Lib::Client;

use feature 'state';

use autodie;

use Moo;

with 'MooX::Attributes::Shadow::Role';

use Hg::Lib::Utils qw[ prep_cmd ];
use Hg::Lib::Server;
use Hg::Lib::Client::Result;
use Hg::Lib::Exception -aliases;

use Types::Standard -all;
use Type::Params qw[ compile ];
use Hg::Lib::Types -types;

Hg::Lib::Server->shadow_attrs;
shadowable_attrs( keys %{ Hg::Lib::Server->shadowed_attrs } );

has _server => (
    is       => 'rwp',
    init_def => undef,
    handles  => [qw(runcommand getencoding)],
);


has eh => (
    is       => 'lazy',
    isa      => RunCommandErrorHandler,
    coerce   => RunCommandErrorHandler->coercion,
    default  => RunCommandErrorHandler->coercion->( 'throw' ),
);

sub BUILD {
    my $self = shift;
    $self->_set__server( Hg::Lib::Server->new_from_attrs( $self ) );
}


=head1 NAME

Hg::Lib::Client

=head1 SYNOPSIS

  $client->run( $cmd, %opts );


=head1 DESCRIPTION

B<Hg::Lib::Client> objects are used to send commands to B<mercurial>'s
command server and retrieve results.  They are created by the
functions in B<Hg::Lib>; see there for more details on how to do so.

=head1 METHODS

=head2 High-level access

=over

=item B<add>

  $res = $client->add( $file, %options );
  $res = $client->add( \@files, %options );

Add the specified file or files to the repository.  The following options
are available:

=over

=item C<include> I<string> | I<ref to array of strings>

Include names matching the given pattern(s).

=item C<exclude> I<string> | I<ref to array of strings>

Exclude names matching the given pattern(s).

=item C<subrepos> I<boolean>

Recurse into subrepositories.

=item C<dryrun> I<boolean>

Do not perform actions, just print output.

=item C<mq> I<boolean>

Operate on patch repository.

=back

=cut

sub add {

    my $self = shift;

    state $check = compile(
        StrList,
        slurpy Dict [
            include  => Optional [StrList],
            exclude  => Optional [StrList],
            subrepos => Optional [Bool],
            dryrun   => Optional [Bool],
            mq       => Optional [Bool],
        ] );

    my ( $filelist, $opts ) = $check->( @_ );

    my $cmd = prep_cmd( 'add', $filelist, $opts );

    return $self->run( $cmd );
}


=back


=head2 Low-level access

=over

=item B<run>

  $client->run( $cmd, %options );

Send a command to the server.  This is a convenience wrapper around
C<Hg::Lib::Server::Pipe::runcommand>.

=over

=item B<$cmd>

The command to execute, typically built using
B<Hg::Lib::Utils::prep_cmd>.  It may be a string or an array of
strings. I<Required>.

=item B<%options>

The following options are available

=over

=item C<prompt>

A reference to a subroutine to be called when the server requires line
based input.  It will be called as

  $data = $prompt->( $max_bytes, $output );

where C<$max_bytes> is the maximum number of bytes to send and
C<$output> is the cumulative data sent on the output channel by the
server for this command.

=item C<input>

A reference to a subroutine to be called when the server requires a
chunk of input data.  It will be called as

  $data = $input->( $max_bytes );

where C<$max_bytes> is  the maximum number of bytes to
send.

=item C<eh>

A reference to a subroutine to be called if an error occurs.  It will
be called as

  $eh->( $ret, $output, $error );

where C<$ret> is the command's return code, and C<$output> and C<$error>
are any data sent on the output and error channels.

=back

=back

=cut

sub run {

    my $self = shift;

    state $check = compile( StrList,
        slurpy Dict [
            prompt => Optional [CodeRef],
            input  => Optional [CodeRef],
            eh     => Optional [RunCommandErrorHandler] ] );

    my ( $cmd, $opts ) = $check->( @_ );

    $opts->{eh} //= $self->eh;

    my ( $output, $error );

    my %outchannel = (
        o => sub { $output .= join( '', @_ ) },
        e => sub { $error  .= join( '', @_ ) } );

    my %inchannel;

    $inchannel{L} = sub { $opts->{prompt}->( @_, $output ) }
      if $opts->{prompt};

    $inchannel{I} = sub { $opts->{input}->( @_ ) }
      if $opts->{input};

    my $ret = $self->runcommand(
        $cmd,
        inchannels  => \%inchannel,
        outchannels => \%outchannel
    );

    my $result = Hg::Lib::Client::Result->new(
        cmd    => $cmd,
        ret    => $ret,
        output => $output,
        error  => $error
    );

    return !$result && defined $opts->{eh}
      ? $opts->{eh}->( $result )
      : $result;
}


=pod

=back

=cut

1;

__END__


=pod


=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Diab Jerius E<lt>djerius@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
