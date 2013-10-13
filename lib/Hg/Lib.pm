use strict;
use warnings;
package Hg::Lib;

# ABSTRACT: Interface to mercurial's command server

use 5.10.1;

use Hg::Lib::Client;
use Hg::Lib::Utils qw[ prep_cmd find_hg ];

use Capture::Tiny 'capture';
use Type::Params qw[ compile ];
use Types::Standard qw[ Str Dict slurpy Optional HashRef Bool Num];
use Hg::Lib::Types -all;

use Hg::Lib::Exception qw[ ECommand ];

our $VERSION = '0.01_05';

my @open_opts = (
    args     => Optional [StrList],
    configs  => Optional [StrList],
    connect  => Optional [Bool],
    encoding => Optional [Str],
    env      => Optional [HashRef],
    hg       => Optional [StrList],
    timeout  => Optional [Num],
);

=head1 NAME

Hg::Lib - interface to mercurial's command server

=head1 SYNOPSIS

  use Hg::Lib;

  # existing repository; start mercurial server

  $client = Hg::Lib::open( path => $dir, %options );

  # initialize a new repository, start mercurial server

  $client = Hg::Lib::init( dest => $dir, %options );

  # clone a repository, start mercurial server in clone

  $client = Hg::Lib::clone( source => $src, dest => $dest, %options );


=head1 DESCRIPTION

B<THIS CODE IS ALPHA QUALITY.> This code is incomplete.  Interfaces
may change.

B<Hg::Lib> is an interface to B<mercurial>'s command
server. (B<mercurial> is a distributed version control system (DVCS)
tool. See L</REFERENCES> for links to  detailed discussions of both
B<mercurial> and its the command server.)

B<mercurial> officially supports two interfaces for interacting with
it: the command line, and its built-in command server.  The command
server runs alongside the controlling program; communications between
the two is via the server's standard input and output streams.
Multiple sequential commands may be issued to the server, reducing the
overhead of starting up B<mercurial> for each command.  The syntax for
using the command server is very similar to issuing commands to the
B<hg> program on the command line.

B<Hg::Lib> manages the start and stop of the server, and marshals
communications between it and user code.  It encapsulates the
interaction with the server in an B<Hg::Lib::CLient> object, whose
methods mirror B<hg>'s commands.



=head1 FUNCTIONS

There are three functions in B<Hg::Lib>:

=over

=item *

B<open> operates on an existing repository.

=item *

B<init> creates a new, empty repository and operates on that

=item *

B<clone> clones an existing repository and operates on the clone

=back

B<mercurial>'s command server only works with an existing repository.
The B<init> and B<clone> functions first create the new repository
using B<hg>, and then start the command server.

Each function returns an B<Hg::Lib::Client> object which is used to
control the server.  By default the server is not actually started
until the client sends it a request.  The C<connect> attribute may be
used to change this behavior.


=over

=item B<open>

  $client = Hg::Lib::open( %args );

Create a client associated with an existing repository.  Throws an
B<Hg::Lib::Exception> object open error.

The following named arguments are available:

=over

=item C<path> I<directory name>

The path to the directory containing the repository.  If not specified,
the current directory is used. I<(Optional)>.

=item C<configs> I<scalar> | I<arrayref>

one or more configuration options to be passed to B<hg> via its
C<--config> option.  See B<hg>'s documentation for more information.
 I<(Optional)>.

=item C<connect> I<boolean>

If false (the default), the command server will be started when
the first command is sent to it.  If true, the command server will
be started immediately.  I<(Optional)>.

=item C<encoding> I<string>

The character set encoding to use.  I<(Optional)>.

=item C<env> I<HashRef>

A hash containing extra environment variables for the command server's
environment.  I<(Optional)>.

=item C<hg> I<scalar> | I<arrayref>

The command used to invoke the B<hg> executable.  If not specified,
the user's path is searched for the C<hg> command.  I<(Optional)>.

=item C<timeout> I<Num>

The time (in seconds) to wait before recieving a response from the
command server.  It defaults to 5 seconds.  I<(Optional)>.

=back


=cut

sub open {

    my $class = shift;

    state $check = compile(
        slurpy Dict [
            path => Optional [Str],
            @open_opts,
        ] );

    return Hg::Lib::Client->new( $check->( @_ ) );
}

sub _xopts {

    my $opts = shift;

    my %opts = (
        configs  => delete $opts->{configs},
        encoding => delete $opts->{encoding},
        env      => delete $opts->{env} // {},
        hg       => delete $opts->{hg} // find_hg(),
        path     => delete $opts->{dest},
        timeout  => delete $opts->{timeout},
        connect  => delete $opts->{connect},
    );

    delete @opts{ grep { ! defined $opts{$_} } keys %opts };

    return %opts;

}

=item B<init>

  $client = Hg::Lib::init( %args );

Initialize a fresh repository and return a client associated with it.  Throws an
B<Hg::Lib::Exception> object open error.

The following named arguments are available:

=over

=item C<dest> I<directory name>

The name of the directory which will contain the new repository.  If
not specified, the repository is created in the current directory.  I<(Optional)>.

=item C<ssh> I<string>

The ssh command to use if connecting to a remote host. I<(Optional)>.

=item C<remotecmd> I<string>

The B<hg> command to run on the remote host. I<(Optional)>.

=item C<insecure> I<boolean>

If true, do not verify server certificate. I<(Optional)>.

=item C<configs> I<scalar> | I<arrayref>

one or more configuration options to be passed to B<hg> via its
C<--config> option. I<(Optional)>.

=item C<connect> I<boolean>

If false (the default), the command server will be started when
the first command is sent to it.  If true, the command server will
be started immediately. I<(Optional)>.

=item C<encoding> I<string>

The locale to use. I<(Optional)>.

=item C<env> I<HashRef>

A hash containing extra environment variables for the command server's
environment. I<(Optional)>.

=item C<hg>  I<scalar> | I<arrayref>

The command used to invoke the B<hg> executable.  If not specified, 
the user's path is searched for the C<hg> command. I<(Optional)>.

=item C<timeout>  I<Num>

The time (in seconds) to wait before recieving a response from the
command server.  It defaults to 5 seconds. I<(Optional)>.

=back

=cut

sub init {

    my $class = shift;

    state $check = compile(
        slurpy Dict [
            insecure  => Optional [Bool],
            remotecmd => Optional [Str],
            ssh       => Optional [Str],
            dest      => Optional [Str],
            @open_opts,
        ] );

    my ( $opts ) = $check->( @_ );

    my %xopts = _xopts( $opts );

    my $cmd = prep_cmd(
        init => [ $xopts{path} // () ],
        $opts
    );

    my ( $stdout, $stderr, $exit ) = capture {
        local %ENV = ( %ENV, %{ $xopts{env} } );
        system( $xopts{hg}, @$cmd );
    };

    ECommand->throw(
		    result =>
		    Hg::Lib::Client::Result->new(
						 cmd    => $cmd,
						 ret    => $exit,
						 output => $stdout,
						 error  => $stderr )
    ) if $exit;

    return Hg::Lib::Client->new( %xopts );
}


=item B<clone>

  $client = Hg::Lib::clone( source => $source, %args );

Clone an existing repository and create a client associated with the
clone.  Throws an B<Hg::Lib::Exception> object open error.

The following named arguments are available:

=over

=item C<source> I<directory name>

The name of the directory which will contain the source repository. I<(Required)>.

=item C<dest> I<directory name>

The name of the directory which will contain the new repository.  If
not specified, a new directory (named after the basename of the source)
containing the clone is created in the current directory.  I<(Optional)>.

=item C<noupdate> I<boolean>

If true, the clone will have an empty working copy.  It defaults to
false.  I<(Optional)>.

=item C<updaterev> I<string>

The revision, tag, or branch to check out. I<(Optional)>.

=item C<ssh> I<string>

The ssh command to use if connecting to a remote host. I<(Optional)>.

=item C<remotecmd> I<string>

The B<hg> command to run on the remote host. I<(Optional)>.

=item C<insecure> I<boolean>

If true, do not verify server certificate. I<(Optional)>.

=item C<configs> I<scalar> | I<arrayref>

one or more configuration options to be passed to B<hg> via its
C<--config> option. I<(Optional)>.

=item C<connect> I<boolean>

If false (the default), the command server will be started when
the first command is sent to it.  If true, the command server will
be started immediately. I<(Optional)>.

=item C<encoding> I<string>

The locale to use. I<(Optional)>.

=item C<env> I<HashRef>

A hash containing extra environment variables for the command server's
environment. I<(Optional)>.

=item C<hg>  I<scalar> | I<arrayref>

The command used to invoke the B<hg> executable.  If not specified,
the user's path is searched for the C<hg> command. I<(Optional)>.

=item C<timeout>  I<Num>

The time (in seconds) to wait before recieving a response from the
command server.  It defaults to 5 seconds. I<(Optional)>.

=back

=cut

sub clone {

    my $self = shift;

    state $check = compile(
        slurpy Dict [
            source       => Str,
            dest         => Optional [Str],
            noupdate     => Optional [Bool],
            updaterev    => Optional [Str],
            rev          => Optional [Str],
            branch       => Optional [Str],
            pull         => Optional [Bool],
            uncompressed => Optional [Bool],
            ssh          => Optional [Str],
            remotecmd    => Optional [Str],
            insecure     => Optional [Bool],
            @open_opts,
        ] );


    my ( $opts ) = $check->( @_ );

    my %xopts = _xopts( $opts );

    my $cmd = prep_cmd(
        clone => [ $xopts{path} // () ],
        $opts
    );


    my ( $stdout, $stderr, $exit ) = capture {
        local %ENV = ( %ENV, %{ $xopts{env} } );
        system( $xopts{hg}, @$cmd );
    };


    ECommand->throw(
		    result =>
		    Hg::Lib::Client::Result->new(
						 cmd    => $cmd,
						 ret    => $exit,
						 output => $stdout,
						 error  => $stderr )
    ) if $exit;

    return Hg::Lib::Client->new( %xopts );
}


1;

__END__

=back

=head1 ERRORS

If an error occurs, an exception in the B<Hg::Lib::Exception>
hierarchy is thrown;  see L<Hg::Lib::Exception> for more details.

=head1 REFERENCES

=over

=item B<mercurial>

L<http://mercurial.selenic.com/>

=item command server

L<http://mercurial.selenic.com/wiki/CommandServer>

=item Python hglib

L<http://mercurial.selenic.com/wiki/PythonHglib>

=back

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Diab Jerius E<lt>djerius@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
