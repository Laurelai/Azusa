#!/usr/bin/perl
package Azusa::Registry;

use strict;
use warnings;
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
       	debug( $self, 'Creating new Azusa::Registry object: '.$self, 10 );
       	$self->{ 'debug_depth' } = 1;
	$self->{registry} = ();
       	return( $self );
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


sub read {  
	my ($self, $key) = @_;
	my ($data, $exist, $realkey);
	my $buffer = $key;
	$buffer    =~ s/(\w+)\.?/{$1}/g;
	$realkey   = '$exist = $self->{registry}'.$buffer.';';
	$buffer    = '$data  = $self->{registry}'.$buffer.'{value}';
	eval($realkey);
	return 0 if (!$exist);
	eval($buffer);
	return 0 if ($@);
	return $data;
}

sub write { 
	my ($self, $key, $value) = @_;
	my $buffer = $key;
	   $buffer =~ s/(\w+)\.?/{$1}/g;
	   $buffer = '$self->{registry}'.$buffer.'{value} = $value;';
	eval($buffer);
	return 0 if ($@);
	return 1;
}

sub delete {  
	my ($self, $key) = @_;
}

sub delete_tree {  
	my ($self, $tree) = @_;
}

sub load { 
	my ($self, $data) = @_;
}

sub dump { 
	my ($self) = @_;
}


1;

