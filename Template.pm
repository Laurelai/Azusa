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
	$self->{cgi_variables}  = 0;
	$self->{anti_xss}       = 1;

       	for( my $x = 0; $x < $#_; $x += 2 ){
               	$self->{$_[$x]} = $_[$x+1];
       	}
	if ($self->{anti_xss}) {
		my $found_html_entities;
		foreach my $directory (@INC) {
			$found_html_entities = 1 if (-e $directory.'/HTML/Entities.pm');
		}
		if (!$found_html_entities) {
			$self->debug('HTML::Entities not found. Disabling anti-XSS measures.');
			$self->{anti_xss} = 0;
		}
		else {
			eval('use HTML::Entities;');
		}
	}

#	handle session and cgi variable interpolation
#	disable the interpolation if no sess/cgi_handle is passed
	if ($self->{sess_variables}) {
		$self->{sess_variables} = 0 if (!$self->{sess_handle});
	}
	if ($self->{cgi_variables}) {
		$self->{cgi_variables}  = 0 if (!$self->{cgi_handle});
	}

	$self->{theme} = 'default' if (!$self->{theme});
#       	$self->{ 'debug_depth' } = 0;
       	debug( $self, 'Creating new Azusa::Template object: '.$self, 10 );
#       	$self->{ 'debug_depth' } = 1;
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
	return($self->parse($template, %variables));
}
sub parse{
	my ($self, $template, %variables) = @_; 
	use DB;
	my ($depth, %called, $recursion) = (0, undef, undef);
	$| = 1;
	for (my $x = 0; (caller($x))[3]; $x++) {
		my (@args) = called_args($x);
		$called{$args[1]}++;
		if ($called{$args[1]} >= $self->{max_recursion}) {
			$recursion = 1;
			print STDERR "*ERROR* Recursion detected in template ".(called_args($x-1))[1].": request for ".$args[1].". Cancelling replacement.\n";
			return('*ERROR* RECURSION DETECTED. Template: '.$args[1]);
		}
		$depth++;
	}
#	while ($template =~ /(\&\([[:alnum:])_\/)]+ \? "(.*)" : "(.*)"\))/g) {
	while ($template =~ /(&\((.*?)\s+(.*?)\s+"(.*?)"\s+\?\s+"(.*?)"\s+:\s+"(.*?)"\))/g) {
#		handle tri-part if blocks with matching.
		my $block      = $1;
		my $variable   = $2;
		my $function   = $3;
		my $check      = $4;
		my $true_case  = $5;
		my $false_case = $6;
		$self->debug('if/match block caught, variable: '.$variable.', function '.$function.', check '.$check, 2);
		$block = quotemeta($block);
		my $repl;
                if ($variable =~ /^sess\./ && $self->{sess_variables}) { # session variable
#                       strip out the sess. part
                        $variable =~ s/^sess\.//;
                        $repl = $self->{sess_handle}->param($variable);
                }
                elsif ($variable =~ /^cgi\./ && $self->{cgi_variables}) { # cgi variable
#                       strip out the cgi. part
                        $variable =~ s/^cgi\.//;
                        $repl = $self->{cgi_handle}->param($variable);
                }
                else {
                        $repl = $variables{$variable}
                }

		my $is_true;
		$self->debug('checking if '.$repl.' '.$function.' '.$check, 2);
		if ($function eq '==') { # match check
			if ($repl eq $check) { $is_true = 1; }
			else { $is_true = 0; }
		}
		if ($function eq '!=') { # match check
			if ($repl ne $check) { $is_true = 1; }
			else { $is_true = 0; }
		}
		if ($function eq '>') { # match check
			if ($repl gt $check) { $is_true = 1; }
			else { $is_true = 0; }
		}
		if ($function eq '<') { # match check
			if ($repl lt $check) { $is_true = 1; }
			else { $is_true = 0; }
		}

		if ($self->{anti_xss}) {
#			$true_case  = encode_entities($true_case);
#			$false_case = encode_entities($false_case);
		}
	
		if ($is_true) {
			$self->debug('block evaluated to true', 2);
			$template =~ s/$block/$true_case/;
		}
		else {
			$self->debug('block evaluated to false', 2);
			$template =~ s/$block/$false_case/;
		}
	}
	while ($template =~ /(\&\(\s*([^ ]+)\s+\?\s+"(.*?)"\s+:\s+"(.*?)"\s*\))/g) {
#		handle tri-part if blocks. 
		my $block      = $1;
		my $variable   = $2;
		my $true_case  = $3;
		my $false_case = $4;
		$self->debug('if block caught, variable: '.$variable, 2);
		$block = quotemeta($block);
		my $repl;
                if ($variable =~ /^sess\./ && $self->{sess_variables}) { # session variable
#                       strip out the sess. part
                        $variable =~ s/^sess\.//;
                        $repl = $self->{sess_handle}->param($variable);
                }
                elsif ($variable =~ /^cgi\./ && $self->{cgi_variables}) { # cgi variable
#                       strip out the cgi. part
                        $variable =~ s/^cgi\.//;
                        $repl = $self->{cgi_handle}->param($variable);
                }
                else {
                        $repl = $variables{$variable}
                }
		if ($self->{anti_xss}) {
#			$true_case  = encode_entities($true_case);
#			$false_case = encode_entities($false_case);
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

	while ($template =~ /\$\{(.*?)\}/g) {
		my $var  = $1;
		my $anti_xss_flag;
		if (substr($var, -1) eq '*') {
			$var = substr($var, 0, -1);
			$anti_xss_flag = '\*';
			$self->debug('Enabling Anti-XSS for \''.$var.'\'', 2);
		}
		my $repl;
		if ($var =~ /^sess\./ && $self->{sess_variables}) { # session variable
#			strip out the sess. part
			my $tmpvar = $var;
			$tmpvar =~ s/^sess\.//;
			$repl = $self->{sess_handle}->param($tmpvar);
			$self->debug('session variable '.$tmpvar.' ('.$var.') replacing with '.$repl, 2);
		}
		elsif ($var =~ /^cgi\./ && $self->{cgi_variables}) { # cgi variable
#			strip out the cgi. part
			my $tmpvar = $var;
			$tmpvar =~ s/^cgi\.//;
			$repl = $self->{cgi_handle}->param($tmpvar);
			$self->debug('cgi variable '.$tmpvar.' replacing with '.$repl, 2);
		}
		else {
			$repl = $variables{$var};
		}
		if ($self->{anti_xss} && $anti_xss_flag) {
			$repl     = encode_entities($repl);
		}
		$self->debug('var is '.$var.': ${'.$var.$anti_xss_flag.'} replaced with '.$repl, 2);
		$var           = quotemeta($var);
#		$anti_xss_flag = quotemeta($anti_xss_flag);
		$self->debug('var is '.$var.': ${'.$var.$anti_xss_flag.'} replaced with '.$repl, 2);
		$template =~ s/\${$var$anti_xss_flag}/$repl/g;
	}
	return($template);
}

1;
