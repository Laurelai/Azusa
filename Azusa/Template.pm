#!/usr/bin/perl
package Azusa::Template;

use strict;
use warnings;
use vars qw/$VERSION/;
# encoding
use MIME::Base64;

$VERSION = '0.0.2';

sub new {
       	my $self = shift;
       	# create a new Azusa object
       	$self = bless( { }, $self );
       	for( my $x = 0; $x < $#_; $x += 2 ){
               	$self->{$_[$x]} = $_[$x+1];
       	}
       	$self->{ 'debug_depth' } = 0;
       	debug( $self, 'Creating new Azusa::Template object: '.$self, 10 );
       	$self->{ 'debug_depth' } = 1;
       	return( $self );
}

sub debug {
       	my( $self, $message, $verbosity ) = @_;

       	if( $self->{'verbosity'} >= $verbosity ) {
               	my( $package, $filename, $line, $subroutine ) = caller( $self->{'debug_depth'} );
               	$subroutine                                   = "main::main" if( !$subroutine );
               	$filename                                     = $0 if( !$filename );
               	$message                                      = '(debug) '.( split( /::/, $subroutine ) )[-1].'@'.$filename.' - '.$message."\n";
               	print( $message );
       	}
       	return( undef );
}

sub render {
	my ($self, $file, %variables) = @_;
	my ($fh, @temp, $template);
	open($fh, '<', './templates/'.$file.'.tpl');
	return(1) if ($@);
	@temp     = <$fh>;
	$template = join('',  @temp);
	close($fh);
	foreach my $key (sort(keys(%variables))) {
		$template =~ s/\${$key}/$variables{$key}/g;
	}
	return($template);
}

1;
