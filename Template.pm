#!/usr/bin/perl
package Azusa::Template;
use Azusa::caller qw[called_args];
use Azusa::version;
use strict;
# use warnings;
use vars qw/$VERSION/;
no warnings;
$VERSION = Azusa::version::version();

sub new {
       	my $self = shift;
#	create a new Azusa object
      	$self = bless( { }, $self );

#	define some default values
	$self->{theme} = 'default';
	$self->{path}  = './templates';

	$self->{verbosity}      = 0;
	$self->{errors_fatal}   = 0;
	$self->{max_recursion}  = 2;
	$self->{sess_variables} = 0;
       	for( my $x = 0; $x < $#_; $x += 2 ){
               	$self->{$_[$x]} = $_[$x+1];
       	}

#	handle session variables
#	disable the interpolation if no sess_handle is passed
	if ($self->{sess_variables}) {
		$self->{sess_variables} = 0 if (!$self->{sess_handle});
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

sub path {
	my ($self, $path) = @_;
	$self->{path} = $path;
}

sub theme {
	my ($self, $theme) = @_;
	$self->{theme} = $theme;
}

sub render {
	my ($self, $file, %variables) = @_;
	use DB;
	my ($depth, %called, $recursion) = (0, undef, undef);
	$| = 1;
	for (my $x = 0; (caller($x))[3]; $x++) {
		my (@args) = called_args($x);
		$called{$args[1]}++;
		if ($called{$args[1]} >= $self->{max_recursion}) {
			$recursion = 1;
			print STDERR "*ERROR* Recursion detected in template ".(called_args($x-1))[1].": request for ".$args[1].". Cancelling replacement.\n";
			return('*ERROR* RECURSION DETECTED. Template: '.$args[1].' (from '.$file.')');
		}
		$depth++;
	}
#	return if ($depth > 5);
	my ($fh, @temp, $template, $error);
	open($fh, '<', $self->{path}.'/'.$self->{theme}.'/'.$file.'.tpl') or $error = $!;
	if ($error) {
		$self->debug($error, 0);
		if ($self->{errors_fatal}) {
			die('*ERROR* Failed to render template '.$self->{path}.'/'.$self->{theme}.'/'.$file.'.tpl: '.$error."\n");
		}
		else {
			return(-1);
		}
	}
	@temp     = <$fh>;
	$template = join('',  @temp);
	close($fh);
#	while ($template =~ /(\&\([[:alnum:])_\/)]+ \? "(.*)" : "(.*)"\))/g) {
#	thanks txt2re!
	while ($template =~ /((&)(\()((?:[a-z][a-z0-9_.]*))( )(\?)( )"(.*?)"( )(:)( )"(.*?)"(\)))/g) {
#		handle tri-part if blocks. 
		my $block      = $1;
		my $variable   = $4;
		my $true_case  = $8;
		my $false_case = $12;
		$self->debug('if block caught, variable: '.$variable, 2);
		$block = quotemeta($block);
		my $repl;
                if ($variable =~ /^sess\./ && $self->{sess_handle}) { # session variable
#                       strip out the sess. part
                        $variable =~ s/^sess\.//;
                        $repl = $self->{sess_handle}->param($variable);
                }
                else {
                        $repl = $variables{$variable}
                }

		if ($repl) {
			$self->debug('block evaluated to true', 2);
			$template =~ s/$block/$true_case/;
		}
		else {
			$self->debug('block evaluated to false', 2);
			$template =~ s/$block/$false_case/;
		}
	}

	if (!$recursion) { 
#		if we aren't in a recursive loop, go ahead and include external templates. 
#		substitute in external templates with variablesk
		while ($template =~ /(\#\{([[:alnum:]_\/]+) (.*?)\})/g) {
			my $match   = $1;
			my $newfile = $2;
			my $varstr  = $3;
			my (%match_variables) = %variables;
			while ($varstr =~ /([[:alnum:]]+):"(.*?)"/g) {
				my ($key, $val) = ($1, $2);
				$match_variables{$key} = $val;
			}
			my $temp = $self->render($newfile, %match_variables);
			$template =~ s/$match/$temp/;
			$template =~ s/\#\{$newfile (.*?)\}/$temp/;
		}
#		substitute in external templates
		while ($template =~ /\%\{([[:alnum:]_\/]+)\}/g) {
			my $newfile = $1; 
			my $temp = $self->render($newfile, %variables);
			$template =~ s/\%\{$newfile\}/$temp/;
		}
	}
#	swap out individual variables

	while ($template =~ /\${([[:alnum:]._\/]+)\}/g) {
		my $repl;
		my $var = $1;
		if ($var =~ /^sess\./ && $self->{sess_handle}) { # session variable
#			strip out the sess. part
			$var =~ s/^sess\.//;
			$repl = $self->{sess_handle}->param($var);
		}
		else {
			$repl = $variables{$var};
		}
		$template =~ s/\${$var}/$repl/g;
	}

#	this sucks.
#	foreach my $key (sort(keys(%variables))) {
#		$template =~ s/\${$key}/$variables{$key}/g;
#	}
	return($template);
}

1;
