#!/usr/bin/perl -w
use strict;

BEGIN {
	use Azusa::version;
	my $azusa_version = Azusa::version::version();
       	$SIG{__DIE__}  = \&handleErrors;
       	$SIG{__WARN__} = \&handleWarnings;
	
	# this code should be removed for production use
	close(STDERR);
	open(STDERR, '>>', 'cgi.stderr'); 

       	sub handleErrors {
               	my ($error) = @_;
               	my ($module, $routine) = (caller(1))[0,3];
               	$module  = 'main' if (!$module);
               	$routine = 'main' if (!$routine);
               	my $traceback;
               	my $y;
               	for ($y = 1; caller($y); $y++) {
                       	# do nothing.
               	}
               	$y--;
               	my $z = 0;
               	$traceback = "Caller traceback:\n";
               	my $sandbox;
               	for (my $x = $y; caller($x); $x--, $z++) {
                       	my $sub  = (caller($x))[3];
                       	my $addr = \&$sub;
                       	$addr    =~ s/(CODE\(|\))//g;
                       	$sub     =~ s/\(eval\)/[eval statement]/g;
                       	$sandbox = 1 if ($sub =~ /eval statement/);
			$sandbox = 0 if ($sub =~ /BEGIN/);
                       	$traceback .= (('&nbsp;' x 2) x $z).($z ? '\_ ' : ' |-').$addr.': <strong>'.$sub.'</strong> at line '.(caller($x))[2].' in file '.(caller($x))[1]."\n";
               	}
               	print <<EOF;
Content-type: text/html

<html>
 <head>
   <title>Error</title>
   <style>
body {
  font-family: monospace;
}
h1 {
  text-align: center;
  color: #FF0000;
}
#trace {
  color: #FF0000;
}
  </style>
 </head>
 <body>
  <h1>Exception raised</h1>Subroutine <strong>$routine</strong> within module <strong>$module</strong> raised exception: <strong>$error</strong><br /><hr />
  <div class="trace"><pre>$traceback</pre></div>
  <hr />
  <address>powered by libAzusa version $azusa_version</address>
 </body>
</html>
EOF
               	exit(1) if (!$sandbox);
       	}
};

1;
