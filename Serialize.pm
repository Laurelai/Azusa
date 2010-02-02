#!/usr/bin/perl
package Azusa::Serialize;

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
	$self->{verbosity} = 0;
       	for( my $x = 0; $x < $#_; $x += 2 ){
               	$self->{$_[$x]} = $_[$x+1];
       	}
       	$self->{ 'debug_depth' } = 0;
       	debug( $self, 'Creating new Azusa::Serialize object: '.$self, 10 );
       	$self->{ 'debug_depth' } = 1;
       	return( $self );
}

sub debug {
       	my( $self, $message, $verbosity ) = @_;
       	if ($self->{'verbosity'} && $self->{'verbosity'} >= $verbosity) {
               	my( $package, $filename, $line, $subroutine ) = caller( $self->{'debug_depth'} );
               	$subroutine                                   = "main::main" if( !$subroutine );
               	$filename                                     = $0 if( !$filename );
               	$message                                      = '(debug) '.( split( /::/, $subroutine ) )[-1].'@'.$filename.' - '.$message."\n";
               	print STDERR ( $message );
       	}
       	return( undef );
}

## serialized hashes (metadata)

sub serialize_hash {
        my( $self, %hash ) = @_;
        my( $key, $value, $buffer );

       	foreach $key ( keys( %hash ) ) {
               	debug( $self, 'serializing entry '.$key, 10 );
                chomp( $value = encode_base64( $hash{ $key } ) );
                chomp( $key   = encode_base64( $key ) );
                $buffer      .= $key."\t".$value."\n";
        }
	return( $buffer );
}

sub unserialize_hash {
        my( $self, $serialized ) = @_;
        my( $key, $value, @buffer, %hash );

        @buffer = split( /\n/, $serialized );
        debug( $self, 'buffer: '.join( '--', @buffer ), 10 );
        for( my $j = 0; $j <= $#buffer; $j++ ){ 
                ( $key, $value ) = split( /\t/, $buffer[ $j ] );
                $hash{ decode_base64( $key ) } = decode_base64( $value );
        }

	return( %hash );
}

## serialized arrays (metadata)

sub serialize_array {
        my( $self, @array ) = @_;
        my( $entry, $value, $buffer );

        for(    $entry   = 0; $entry <= $#array; $entry++  ) {
                $value   = encode_base64( $array[ $entry ] );
                $buffer .= encode_base64( $entry )."\t".$value."\n";
        }
	return( $buffer );
}

sub unserialize_array {
        my( $self, $serialized ) = @_;
        my( $entry, $value, @buffer, @array );

        @buffer = split( /\n/, $serialized );
        for ( $entry = 0; $entry < $#buffer; $entry++ ) {
                $value  = decode_base64( ( split( /\t/, $buffer[ $value ] ) )[ 1 ] );
                $array[ $entry ] = $value;
        }
	return( @array );
}


1;
