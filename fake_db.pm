
use 5.012;
use strict;
use warnings;
use Storable;
our @EXPORT = (); 		#You may even omit this line
our @EXPORT_OK = ();	
use base qw(Exporter);

{
	package EmFakeDb;
	sub new {
		ref(my $class = shift ) and die 'CLASS ONLY';
		my %dc = (
			userpass => ['default user name', 'default password' ],
			states=> {
				imagesize => 'qcif',
				imagequality => 3,	#0,1,2,3,4,5
				bitrate => 50,		#0~63
				framerate => 20,		#1~30
				IDRvalue => 10,		#1~20
			}
		);
		bless  \%dc,$class;
	}
	
	sub print {
		ref(my $me = shift) or die 'INSTANCE ONLY';
		my $width = 60;
		
		my @infos;
		push @infos,"    user-password = ( ${${$me}{userpass}}[0] , ${$me}{userpass}->[1] )";
		my $states = ${$me}{states};
		while( my($key,$value) = each %$states ) {
			push @infos,  sprintf("     %12s = %-12s",$key,$value);
		}
		
		say '+'.'-'x($width-2) .'+';
		for(@infos) {
			$_ = '|' . $_;
			$_ .= ' ' x ($width - 1 - length ) .'|';
			say;
		}
		say '+'.'-'x($width-2) .'+';
		1;
	}
	
	sub store {
		ref(my $me = shift) or die 'INSTANCE ONLY';
		Storable::store  $me, EmFakeDb::store_name();
		$me;
	}
	
	sub retrieve {
		ref(my $me = shift) and die 'CLASS ONLY';
		Storable::retrieve EmFakeDb::store_name();     #Does this work?
		#my ($user,$pass) = retrieve  'some_file';
		#say "This is $user, $pass";
	}
	
	sub username {
		ref(my $me=shift) or die 'INSTANCE ONLY';
		${$me}{userpass}->[0];
	}
	
	sub setUsername {
		ref(my $me=shift) or die 'INSTANCE ONLY';
		${$me}{userpass}->[0] = shift or die 'No new user name for me';
	}
	
	sub password {
		ref(my $me=shift) or die 'INSTANCE ONLY';
		${$me}{userpass}->[1];
	}
	
	sub setPassword {
		ref(my $me = shift) or die 'INSTANCE ONLY';
		${$me}{userpass}->[1] = shift or die 'No password for me';
	}
	
	sub  states {
		ref(my $me=shift) or die 'INSTANCE ONLY';
		%{${$me}{states}};
	}
	
	sub statesRef {
		ref(my $me = shift) or die 'INSTANCE ONLY';
		${$me}{states};		#Reference returned.
	}
	
	sub setStates {
		ref(my $me=shift) or die 'INSTANCE ONLY';
		%{${$me}{states}} = shift or die 'NO STATES FOR ME';
	}
	
	#And this is static 
	sub store_name {
		'fake_db';
	}
}

1;

