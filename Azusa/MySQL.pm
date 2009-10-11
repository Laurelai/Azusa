#!/usr/bin/perl -w
package Azusa::MySQL;

use strict;
use warnings;
use vars qw/$VERSION/;

# databases
use DBI;
use DBD::mysql;

$VERSION = '0.0.2';

sub new {
       	my $self = shift;
       	# create a new Azusa object
       	$self = bless( { }, $self );
       	for( my $x = 0; $x < $#_; $x += 2 ){
               	$self->{$_[$x]} = $_[$x+1];
       	}
       	$self->{ 'debug_depth' } = 0;
       	debug( $self, 'Creating new Azusa::MySQL object: '.$self, 10 );
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

sub login {
	my( $self ) = @_;
        my( $temp )           = DBI->connect(sprintf(
                'DBI:mysql:%s:%s', $self->{db_name}, $self->{db_host}),
                $self->{db_user},
                $self->{db_pass});
        if (!$temp || DBI->errstr) {
                return(1);
        }
	$self->{db_handle} = $temp;
        return(0);
}

sub query {
	my ($self, $query) = (shift, shift); # keep the rest of @_ clean
        my ($qstring, $temp, $dbh, $qh);
        $dbh               = $self->{db_handle};
        $qstring           = '$qh = $dbh->prepare(sprintf($query';
        for (my $x = 0; $x < $#_; $x++) {
                next if (!$_[$x]);
                my ($isvar, $isvar2);
                ($isvar, $isvar2) = ('$dbh->quote(', ')')
                        if ($_[$x] =~ /([[:alpha:]]|')/);
                $qstring .= ', '.$isvar.'$_['.$x.']'.$isvar2;
        }
	$qstring .= '));';
        eval($qstring);
        $qh->execute;
        $self->{query_count}++;
        my (@return, @temp);
        while (@temp = $qh->fetchrow_array) {
                push(@return, @temp);
        }
	return(@return);
}

1;