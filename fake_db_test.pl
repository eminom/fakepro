
use 5.012;
use strict;
use warnings;
use fake_db qw/EmFakeDb/;

use Test::More 'no_plan';

ok( my$ debi = EmFakeDb->new, 'Construction');
ok($debi->print, 'Operation of print');

my ($name,$password) = ( 'admin1', 'topsecret');

is( $debi->setUsername($name), $name , 'Assignment of name');
is( $debi->setPassword($password), $password, 'Updating of password');
ok( $debi->store->print, 'Store-Retrieve-Print chain');

$debi = EmFakeDb->retrieve;

is($name, $debi->username, 'Name test');
is( $password, $debi->password, 'Password verify');

ok( 
	eval	{
		say 'This is states:';
		my %dc = $debi->states;
		foreach(keys %dc ) {
			say "\t$_ -> $dc{$_}";
		}
		$debi->print;
	},
	'Showing of states.'
);

ok(
	eval {
		my $states = $debi->statesRef;
		$states->{imagesize} = 'h264';
	},
	'Setting of states'
);

ok( $debi->print, 'Print again');
ok( ref($debi->store), 'Store finally.');
#exit 0; does affect the return value to the shell.