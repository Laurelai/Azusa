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
	$self->{verbosity}         = 0;
	$self->{errors_fatal}      = 1;

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
               	print STDERR ( $message );
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
		$self->debug('Failed to login to server: '.DBI->errstr, 0);
		die(DBI->errstr."\n") if ($self->{errors_fatal});
                return(DBI->errstr);
        }
	$self->{db_handle}    = $temp;
	$self->{db_logged_in} = 1;
        return(0);
}

sub query {
	my ($self, $query) = (shift, shift); # keep the rest of @_ clean
	$self->login if (!$self->{db_logged_in});
        my ($qstring, $temp, $dbh, $qh, $errstr);
	$self->debug($query, 2);
        $dbh               = $self->{db_handle};
	$dbh->{RaiseError} = $self->{errors_fatal};
        $qstring           = '$qh = $dbh->prepare(sprintf($query';
        for (my $x = 0; $x <= $#_; $x++) {
#                next if (!$_[$x]); # this is bad for %d and zeroes
                my ($isvar, $isvar2);
                ($isvar, $isvar2) = ('$dbh->quote(', ')')
                        if ($_[$x] !~ /^(\d+)$/);
                $qstring .= ', '.$isvar.'$_['.$x.']'.$isvar2;
        }
	$qstring .= '))'.($self->{errors_fatal} ? ' or die($dbh->errstr);' : ';');
	$self->debug($qstring, 2);
        eval($qstring);
	if (0) { # $errstr) {
		$self->debug('SQL Query error: '.$errstr, 0);
		die($errstr."\n") if ($self->{errors_fatal});
		return(0);
	}
        $qh->execute;
        $self->{query_count}++;
        my (@return, @temp);
	if ($query =~ /^SELECT/) {
	        while (@temp = $qh->fetchrow_array) {
	                push(@return, @temp);
	        }
		return(@return);
	}
}

sub last_insert_id {
	my ($self) = @_;
	my $dbh    = $self->{db_handle};
	return($dbh->last_insert_id(undef, undef, undef, undef));
}
1;
