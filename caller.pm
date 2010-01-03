#!/usr/bin/perl -w
# use strict; # strict breaks this module as it uses symbol refs
# This is more or less copy/pasted from cpan. 
# It's used internally in Template for recursion detection
package DB;
sub called_args {
	my ($level) = @_;
	my @foo = caller( ( $level || 0 ) + 2);
	wantarray ? @DB::args : \@DB::args;
}

package Azusa::caller;
use DB;
$Azusa::caller::VERSION   = '1.4';
sub import {
    *{(caller)[0].'::called_args'} = \&called_args
      if $_[1] eq 'called_args';
}
sub called_args { &DB::called_args(@_); }

1;

__END__
