#!/usr/bin/perl
package Azusa::Security;

use strict;
use warnings;
use vars qw/$VERSION/;
use Digest::SHA1 qw/sha1_hex/;
use Digest::MD5  qw/md5_hex/;

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
       	debug( $self, 'Creating new Azusa::Security object: '.$self, 10 );
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

sub hash { sha1_hex(md5_hex($_[1]).$_[2]); }

sub aphash {
        my ($password, $revflag) = @_;
        my ($salt, @chars, $hash);
        @chars = split(//, $password);
        @chars = reverse(@chars) if ($revflag);
        $salt = 0;
        my $i = 0;
        foreach my $char (@chars) {
                $i++;
                # simple AP hash
                $salt ^= (($i & 1) == 0) ? ( ($salt << 7) ^ ord($char) ^ ($salt >> 3) ) : (~(($salt << 11) ^ ord($char) ^ ($salt >> 5)));

        }
#       printf("genkey %s\n", $salt);
        srand($salt);
        $salt  = rand(65536);
        $salt .= int(rand(9)) while (length($salt) < 18);
        $salt  =~ s/\.//g;
#       printf("parthash: %x revflag: %d\n", $salt, $revflag);
        return($salt) if ($revflag);
        $salt .= gen_salt($password, 1);
        $salt  = substr($salt, 0, 32);
        @chars = split(//, $salt);
        undef($salt);
        for (my $x = 0; $x < 32; $x += 2) {
                $salt .= sprintf('%02x', $chars[$x].$chars[$x+1]);
        }
        return($salt);
}	


1;
