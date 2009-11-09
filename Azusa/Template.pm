#!/usr/bin/perl
package Azusa::Template;
use Azusa::caller qw[called_args];
use strict;
# use warnings;
use vars qw/$VERSION/;
no warnings;
$VERSION = '0.0.2';

sub new {
       	my $self = shift;
       	# create a new Azusa object
       	$self = bless( { }, $self );
       	for( my $x = 0; $x < $#_; $x += 2 ){
               	$self->{$_[$x]} = $_[$x+1];
       	}
	$self->{theme} = 'default' if (!$self->{theme});
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
               	print STDERR $message;
       	}
       	return( undef );
}

sub render {
	my ($self, $file, %variables) = @_;
	my ($theme)                   = $self->{theme};
	use DB;
	my ($depth, %called, $recursion) = (0, undef, undef);
	$| = 1;
#	print STDERR 'call tree: ';
	for (my $x = 0; (caller($x))[3]; $x++) {
		# hm, well, i don't think i can check the args with caller() sec
#		print STDERR "[$x] ".(caller($x))[3]."(";
		my (@args) = called_args($x);
#		print STDERR $args[1].")\n";
#		print STDERR ' '.$args[1];
		$called{$args[1]}++;
#		print STDERR $args[0]."->render(".$args[1].", ".$args[2]."); called ".$called{$args[1]}." times (run from ".$file.")\n";
		if ($called{$args[1]} >= 2) {
			print STDERR "*WARNING* Recursion detected in template ".(called_args($x-1))[1].": request for ".$args[1].". Cancelling replacement.\n";
			$recursion = 1;
			return('*ERROR* RECURSION DETECTED. Template: '.$args[1].' (from '.$file.')');
		}
		$depth++;
	}
#	print STDERR "\n";
	return if ($depth > 5);
	# tabs always sucked in this regard.
	printf STDERR (('['.$depth.'] |'."-" x $depth).' Rendering template '.$file.', theme '.$theme."\n");
	my ($fh, @temp, $template);
	open($fh, '<', './templates/'.$theme.'/'.$file.'.tpl');
	$self->debug($@, 0) if ($@); 
	return(1) if ($@); 
	@temp     = <$fh>;
	$template = join('',  @temp);
	close($fh);
	if (!$recursion) { # if we aren't in a recursive loop, go ahead and include external templates. 
		# substitute in external templates with variablesk
		while ($template =~ /(\#\{([[:alnum:]_\/]+) (.*?)\})/g) { # 0wn3dlol stupid nano.
					# ^ I'm trying to grab what it matched. it's usually the first element. $1
					# close, but I want the entire block it matched.  $0 is the same as argv[0] 
			my $match   = $1; # i love you. lol
			my $newfile = $2;  # <-- here
	 		# no, well, yes, but no, the code i'm going to write covers both cases. lolcock
			my $varstr  = $3;
			my (%match_variables) = %variables;
			while ($varstr =~ /([[:alnum:]]+):"(.*?)"/g) {
				my ($key, $val) = ($1, $2);
	#			$self->debug('internal replace: '.$key.' => '.$val, 0);
				$match_variables{$key} = $val;
			}
			my $temp = $self->render($newfile, %match_variables);
			$template =~ s/$match/$temp/;	# right, but even though it is ambigfuckspelling, it only matches once. and the ones that are matched beore
								# are already gone, so it wouldn't matter either way. but this is good. o, tru.
			$template =~ s/\#\{$newfile (.*?)\}/$temp/;
		}
		# substitute in external templates
		while ($template =~ /\%\{([[:alnum:]_\/]+)\}/g) {
			my $newfile = $1; 
			my $temp = $self->render($newfile, %variables);
			$template =~ s/\%\{$newfile\}/$temp/;
		}
	}
	# swap out individual variables
	foreach my $key (sort(keys(%variables))) {
		$template =~ s/\${$key}/$variables{$key}/g;
	}
	return($template);
}

1;
