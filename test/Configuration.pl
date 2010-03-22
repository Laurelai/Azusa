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
print "passed\npassed all tests!\n";
exit(0);

