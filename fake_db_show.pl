use 5.012;
use strict;
use warnings;
use fake_db qw/EmFakeDb/;

my $db = EmFakeDb->retrieve;
$db->print;

say "(UserName, Password) = (",$db->username,',', $db->password, q{)};
printf "%-60s\n", "States Retrieved:".'*'x20;
my %dc = $db->states;
foreach(keys %dc) {
	say "\t$_:$dc{$_}";
}
printf '%-60s', '*'x60;


