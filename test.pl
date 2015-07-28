
use 5.012;
use strict;
use warnings;
use IO::Dir;



my $dirs = IO::Dir->new('.') or die "Cannot open current directory:$!";

say join "\n", map { sprintf ("%-30s", q{"} . $_ . q{"}) . '.'x20 . q{    } . 
	sprintf('%10s',system("perl $_ ")?'failed':'passed')  } grep { /\S+test\.pl/xmsi  and -f } $dirs->read;
	
$dirs->close;