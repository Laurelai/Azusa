#!/usr/bin/perl
package Azusa::Session;

use strict;
use warnings;
use CGI::Session;
use vars qw/$VERSION/;
use Azusa::version;
$VERSION = Azusa::version::version();

sub new {
       	my $self = shift;
       	# create a new Azusa object
       	$self = bless( { }, $self );
	$self->{verbosity} = 0;
       	for( my $x = 0; $x < $#_; $x += 2 ){
               	$self->{$_[$x]} = $_[$x+1];
       	}
       	$self->{ 'debug_depth' } = 0;
       	debug( $self, 'Creating new Azusa::Session object: '.$self, 10 );
       	$self->{ 'debug_depth' } = 1;
	
	$self->{session} = CGI::Session->load();
	if ($self->{session}) {
		if ( $self->{session}->is_expired || !$self->id ) { # if the session died or is empty (we fill it with a stub) recreate it
			$self->{session} = $self->{session}->new();
			$self->debug('new session '.$self->id, 1);
			$self->param('azusa', 'true');
			$self->expire(0); # let the user set an expiration
		}
		else {
			$self->debug('returning session '.$self->id, 1);
		}
	}
	else {
		$self->debug('failed to load session for some reason. check permissions?', 1);
		return(undef);
	}
       	return( $self );
}

sub param  { if (!$_[2]) { return $_[0]->{session}->param($_[1]); } else { return $_[0]->{session}->param($_[1], $_[2]); } }
sub expire { $_[0]->{session}->expire($_[1], $_[2]); }
sub id     { return $_[0]->{session}->id; }
sub header { print $_[0]->{session}->header; }
sub cookie { CGI::Cookie->new(-name => $_[0]->{session}->name, -value => $_[0]->id); }

sub debug {
       	my( $self, $message, $verbosity ) = @_;

       	if( $self->{'verbosity'} >= $verbosity ) {
               	my( $package, $filename, $line, $subroutine ) = caller( $self->{'debug_depth'} );
               	$subroutine                                   = "main::main" if( !$subroutine );
               	$filename                                     = $0 if( !$filename );
               	$message                                      = '(debug) '.( split( /::/, $subroutine ) )[-1].'@'.$filename.' - '.$message."\n";
               	print STDERR ( $message );
       	}
       	return( undef );
}


1;
