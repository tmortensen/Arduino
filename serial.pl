#!/usr/bin/env perl

use warnings;
use v5.10;
use strict;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use JSON;
use Device::SerialPort;

# Vars

my $now = localtime;
my $API_KEY = '7c8db14423b983d037478ed882c270c36b4d224886aeb6fd22eb220d7eddd60c';
my $DEVICE = 'testrig@tmortensen.tmortensen';
my $SERIAL_PORT = '/dev/ttyACM0';
my $API = 'http://api.carriots.com/streams';
my $json;


# Set up the serial port
my $port = Device::SerialPort->new($SERIAL_PORT);

# 19200, 81N on the USB ftdi driver
$port->baudrate(19200); # you may change this value
$port->databits(8); # but not this and the two following
$port->parity("none");
$port->stopbits(1);
$port->dtr_active(0);

#sleep 1;
#requestTemps();


#$port->write("1");
getPayload();

sub getPayload {

	requestTemps();
	while (1) {
# Poll to see if any data is coming in
		my $char = $port->lookfor();

# Received character: [Address: 28641AF7040000A9 TempC: 24.00 TempF: 75.20] 

		if ($char) { 
			chop $char;
			#say $char;
			if ($char =~ m/(.*),(.*),(.*),(.*),(.*)/) {
				#if ($char =~ m/(.*),(.*),(.*)/) {
				#$Temp1,$Temp2,$Temp3 = split(/,/, $char, 3);
				my $Temp1 = $1;
				my $Temp2 = $2;
				my $Temp3 = $3;
				my $Humid = $4;
				my $HumidTemp = $5;
				$json = '{ 
				"protocol":"v2",
				"at":"now",
				"device":"' . $DEVICE . '",
				"data":{ 
				"Temp1":"' . $Temp1 . '",
				"Temp2":"' . $Temp2 . '",
				"Temp3":"' . $Temp3 . '",
				"Humid":"' . $Humid . '",
				"HumidTemp":"' . $HumidTemp . '"
				},
				"checksum":""
				}';
				SendToCarriots($API, $API_KEY, $json);
			}
			$now = localtime;
			say "$now : got chop and sauce";
			return 1;
		}
		$now = localtime;
		say "$now : chop but no sauce [$char]";
	}
	return 1;
}

# Uncomment the following lines, for slower reading,
# but lower CPU usage, and to avoid
# buffer overflow due to sleep function.

# $port->lookclear;
# sleep (1);


# json = ' 
#     {
#    "protocol":"v2",
#    "at":"now",
#    "device":"yourDevice@yourUserName",
#    "data":{
#    "Temperature":"21.05",
#    "Humidity":"58.50"
#    },
#    "checksum":""
#    }';

sub requestTemps {
	sleep 2;
	$port->write("1");
	sleep 2;
}

sub SendToCarriots {

	my $api = shift;
	my $key = shift;
	my $json = shift;
	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new( POST => $api);
	my $length = length($json);

	$now = localtime;
	say "$now : Debug : api [$api] : key [$key] json [$json] jsonlength [$length]"; 

	$req->header( 'Content-Type' => 'application/json' );
	$req->header( 'carriots.apikey' => $key );
	$req->header( 'Content-Length' => $length );
	$req->content( $json );

	my $res = $ua->request($req);

	if ($res->is_success) {
		print $req->as_string;
	} else {
		print $res->status_line;
	}
}
