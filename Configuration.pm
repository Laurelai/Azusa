#!/usr/bin/perl
package Azusa::Configuration;

use strict;
use warnings;
use vars qw/$VERSION/;
use Azusa::version;
$VERSION = Azusa::version::version();

sub new {
       	my $self = shift;
       	# create a new Azusa object
       	$self = bless( { }, $self );
	$self->{verbosity}     = 0;
	$self->{strict_syntax} = 0;
       	for( my $x = 0; $x < $#_; $x += 2 ){
               	$self->{$_[$x]} = $_[$x+1];
       	}
       	$self->{ 'debug_depth' } = 0;
       	debug( $self, 'Creating new Azusa::Configuration object: '.$self, 10 );
       	$self->{ 'debug_depth' } = 1;
       	return( $self );
}

sub load {
	my ($self, $file, $config) = @_;
	my $fh;
	open($fh, '<', $file) or return((0, 'Error opening '.$file.': '.$!));
	my ($key, $val);
	my $line = 0;
	while (my $buffer = <$fh>) {
		$line++;
		undef($key); undef($val);
		chomp($buffer);
		next if ($buffer =~ /^#/ || !$buffer || $buffer =~ /^\s+$/);
		if ($buffer =~ m/\s*(.*?)\s*=\s*"((?:\\"|[^"])+?)"\s*$/) {
			($key, $val) = ($1, $2);
			$val         =~ s/\\"/"/g;
		}
		elsif ($buffer =~ m/\s*(.*?)\s*=\s*"((?:\\"|[^"])+?)"\s*,.*/) { # match an array
			$key        = $1;
			# just discard the first match, we get it again. 
			my (@array, $tempval);
			while ($buffer =~ /,?\s*"((?:\\"|[^"])+?)"\s*/g) {
				my $tempval = $1;
				$self->debug('Matching array value '.($#array + 2).' to '.$tempval, 2);
				push(@array, $tempval);
			}
			$val = \@array;
		}	
		else {
			return((0, 'Syntax error on line '.$line.' near: > '.$buffer)) if ($self->{strict_syntax});
			next;
		}
		$config->{$key} = $val;
		$self->debug($file.':'.$line.' - config key "'.$key.'" set to "'.$val.'"', 1);
	}
	close($fh);
	return(1);
}


sub debug {
       	my( $self, $message, $verbosity ) = @_;

       	if( $self->{'verbosity'} >= $verbosity ) {
               	my( $package, $filename, $line, $subroutine ) = caller( $self->{'debug_depth'} );
               	$subroutine                                   = "main::main" if( !$subroutine );
               	$filename                                     = $0 if( !$filename );
               	$message                                      = '(debug) '.( split( /::/, $subroutine ) )[-1].'@'.$filename.' - '.$message."\n";
               	print STDERR ($message );
       	}
       	return( undef );
}


1;
