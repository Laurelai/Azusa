#!/usr/bin/perl -w
use lib '../..';
use strict;
use Azusa::Configuration;

my $conf = Azusa::Configuration->new(verbosity => 10);
my %info;

my ($lp, $err) = $conf->load('test.conf', \%info);
die('load() failed: '.$err."\n") if (!$lp);
	
$| = 1;
print 'test #1: ';
die("failed\n") if ($info{test1} ne 'hello world');
print "passed\ntest #2: ";
die("failed\n") if ($info{test2} ne 'hello "world"');
print "passed\ntest #3: ";
die("failed\n") if ($info{test3} != 12345.67890);
print "passed\ntest #4: ";
die("failed\n") if ($info{test4} ne 'i wish i was a bird');
print "passed\ntest #5: ";
die("failed\n") if ($info{test5} ne '~~~*($@%@$#^@#$^@*!');
print "passed\ntest #6: ";
die("failed\n") if ($info{test6} ne 'desu~');
print "passed\npassed first test suite\n";

print "testing parsing errors\n";
print "test #1: ";
$conf->{strict_syntax} = 1;
($lp, $err) = $conf->load('test2.conf', \%info);
die("failed\n") if ($lp);
print "passed\npassed second test suite\n";

exit(0);

