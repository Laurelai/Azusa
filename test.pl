#!/usr/bin/perl -w
use strict; 

use Azusa::Serialize;
use Azusa::MySQL;

use Data::Dumper;

my $serial = Azusa::Serialize->new(verbosity => 10);
my $hash = $serial->serialize_hash( ('yes' => 'no', 'piss' => 'dicks') );
print $hash."\n\n";
my %new  = $serial->unserialize_hash( $hash );
print Dumper(%new)."\n\n";

my $sql  = Azusa::MySQL->new(verbosity => 10, 
		      db_user => 'fifo', 
		      db_pass => 'piss', 
		      db_host => 'mysql.frantech.ca', 
		      db_name => 'fifo');
$sql->login();
my ($uid, $email) = $sql->query('SELECT uid,email FROM passwd WHERE username = %s and uid = %d', "test", 1);
printf('Got: uid %d, email %s'."\n", $uid, $email);