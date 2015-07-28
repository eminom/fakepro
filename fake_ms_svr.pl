use 5.012;
use strict;
use warnings;
use Time::HiRes qw(usleep);
use IO::Handle;
use Socket qw(SOCK_STREAM inet_ntoa inet_aton AF_INET SOMAXCONN INADDR_ANY sockaddr_in);
use fake_db qw/EmFakeDb/;

my $counter = 0;
my $globSessionName = 'Global Session';

sub randomName
{
	my $str = '';
	for(0..5){
		$str .= chr ord('a') + int(rand 26);
	}
	$str;
}

sub serveClient
{
	my $clt = shift or die 'no socket for me ?';
	my $myName = shift or die 'no name for me?';
	
	say "Client Session:[$myName] ". '*'x23;
	my $db = EmFakeDb->retrieve;
	my $states =  $db->statesRef;
	$db->print;
	say "[$myName]:with ",$db->username,'=',$db->password;

	$counter++;
	say "[$globSessionName]:Client up to $counter.";
	
	MainProcess_serveClient:
	while( defined (my $line = <$clt>) ) {
					#The counterpart:>>> #$clt->sysread(my $line,1024)
		chomp $line;
		if( $line =~ /\Areq\s+(?<reqID>\d+)\s+?(?<req>.+)/xms ) {
			#print "[$myName]:$1,$2\n";
			#need to response correctly here.
			#should switch $2
			my ($resString,$resCode,$logString) = 'no language';
			die if defined($resCode);
			die if defined($logString);
			given ($+{req})
			{
				when ( /\Alogin\s+([\w\d]+)\s+([\w\d]+)/xms ) {
					$logString = "Try to login with name=$1,password=$2";
					if (not( $db->username eq $1 && $db->password eq $2 )) {
						$resCode = 200;	# error
						$resString = 'login denied';
						$logString .= "\n\tError username-password combination.";
						last MainProcess_serveClient;
						# Todo: to disconnect the illegal user.
					}
					else {
						$resCode = 100;	# success 
						$resString = 'login granted';
						$logString .="\n\tAccess granted.";
					}
				}
				when ( /\Aretrieveconfig/xms ) {
					$resCode = 100;
					$resString = "currentconfig $states->{imagesize}/"
						."$states->{imagequality}/"
						."$states->{bitrate}/"
						."$states->{framerate}/"
						."$states->{IDRvalue}";
					$logString = "Retrieve current configration:*$resString*";
				}
				when ( /\Aconfig\s+(\w+)\s+([\w\d]+)/xms ) {
					given ($1) {
						when ( 'imagesize' ) {
							$logString = "image size updated to $2, (old = $states->{imagesize})";
							$states->{imagesize} = $2;
						}
						when ( 'imagequality' ) {
							$logString = "image quality updated to $2, (old = $states->{imagequality})";
							$states->{imagequality} = $2;
						}
						when ( 'bitrate' ) {
							$logString = "bit-rate updated to $2, (old = $states->{bitrate})";
							$states->{bitrate} = $2;
						}
						when ( 'framerate' ) {
							$logString = "frame-rate updated to $2, (old = $states->{framerate})";
							$states->{framerate} = $2;
						}
						when ( 'IDRvalue' ) {
							$logString = "DRvalue updated to $2, (old = $states->{IDRvalue})";
							$states->{IDRvalue} = $2;
						}
					}
				}
				when ( /\Adevice\s+(?<opera>\w+)/xms ) {
					given ($+{opera}) {
						when ( 'on' ) {
							$logString  = 'Turn me on.';
						}
						when ( 'off' ) {
							$logString =  'Turn me off.';
						}
						when ( 'reboot' ) {
							$logString =  'Reboot me';
						}
					}
				}
				when ( /passwd\s+(?<newpasswd>[\d\w]+)/ ) {
					$logString = 'Change password from ' . $db->password . " to $+{newpasswd}";
					$resString = 'passwd updated';
					$resCode = 100;
					$db->setPassword( $+{newpasswd} );  #update to that
				}
			}
			
			$resCode = defined($resCode) ? $resCode:
				defined($logString)? 100:200;
				
			print {$clt} "res $+{reqID} $resCode $resString\r\n";
			$clt->autoflush(1);	
			#$clt->syswrite("res $+{reqID} $resCode $resString\r\n");
			
			if (defined($logString) ) {
				say "[$myName]:$logString";
			}
			else {
				say "[$myName]:Unknown command:$line";
			}
			
			
		}# end of request check
	}
	
	$db->store;
	undef $db;
	close $clt;		#almost by force
	$counter--;
	say "[$globSessionName]:Client down to $counter.";
	
	exit;
}

#The simple framework for server
sub runTcpServerOnPort
{
	#pre: fetch
	my $port = shift or die 'no parameter for my port';
	ref(my $sub_ref = shift) or die 'no parameter for my client sub';
	
	#welcome:
	say 'fake-server 0.01 run @ '.localtime;
	
	#init:
	my $proto = getprotobyname('tcp') or die "cannot get tcp:$!";
	socket my $svr, Socket::AF_INET, Socket::SOCK_STREAM
		, $proto or die "Cannot create svr:$!";
	my $addr = sockaddr_in($port,Socket::INADDR_ANY);
	bind $svr, $addr or die "Cannot bind to port $port for:$!";
	listen $svr, Socket::SOMAXCONN or die "Cannot listen-mode:$!";
	#And here comes the skeleton
	for(;my $addr = accept(my $theClient,$svr); ){
		print {$theClient} "cha xxxx\r\n";
		$theClient->autoflush(1);	# Nov.15.2o1o. from textbook
		#$theClient->syswrite("cha xxxx");
		
		if( defined(my $res = <$theClient>) ) {
			chomp $res;
			if( $res =~ /^roger\soooo/xms ) {
				defined(my $pid=fork) or die "cannot fork:$!";
				&{$sub_ref}($theClient, randomName) unless ($pid);  #The sub should die on its own.
				close $theClient;
				next;
			}
			else {
				print "This is wrong response:$res";
				say 'Sigh';
			}
		}
		say 'Illegal connection detected.';
		close $theClient or die 'Cannot shutdown illegal connection';
	}
	close $svr;
}



runTcpServerOnPort(7999,\&serveClient);
