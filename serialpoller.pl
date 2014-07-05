#!/usr/bin/env perl

use warnings;
use v5.10;
use strict;
use Device::SerialPort;
use File::stat;
use Fcntl ':flock'; # contains LOCK_EX (2) and LOCK_SH
use File::Basename;
use POSIX qw(setuid getuid);

# Vars
our $debug = 1;

my $SERIAL_PORT = '/dev/ttyACM0';
my $max_cache_age = 60; # 1 Minutes
my $SCRIPT = basename($0);
my $LOGFILE = "/tmp/$SCRIPT.log";
my $CACHE_DIR="/dev/shm";
my $CACHE_FILE=$CACHE_DIR . '/' . 'greenhouse.info';
my $DEBUG_FILE=$CACHE_DIR . '/' . 'debug.info';
$LOGFILE = $DEBUG_FILE;
my $RUNASUSER = 'nobody'; # for DropPrivs($RUNASUSER); 

ClearLog("Start");

# Set up the serial port
my $port = Device::SerialPort->new($SERIAL_PORT);

# 19200, 81N on the USB ftdi driver
$port->baudrate(19200); # you may change this value
$port->databits(8); # but not this and the two following
$port->parity("none");
$port->stopbits(1);
$port->dtr_active(0);


my $data = getPayload();

CacheResults($CACHE_FILE, $data);

LogIt("End");
sub getPayload {

	my $counter = 0;
	requestData();
	while (1) {
		$counter++;
		if ( $counter == 10000 ) {
		  LogIt("Counter Max Reached [$counter]");
			die "DIE: Unable to get results\n";
		}
		elsif ( $counter < 10000 ) {
		  LogIt("+", '') if $debug;
		}
		#Poll to see if any data is coming in
		my $char = $port->lookfor();
		if ($char) { 
			chop $char;
			if ($char =~ m/(\d{1,3}\.\d{1,3}),(\d{1,3}\.\d{1,3}),(\d{1,3}\.\d{1,3}),(\d{1,3}\.\d{1,3}),(\d{1,3}\.\d{1,3})/) {
				my $Temp1 = $1;
				my $Temp2 = $2;
				my $Temp3 = $3;
				my $Humidity = $4;
				my $HumidityTemp = $5;
				my $data = "Temp1:$Temp1\nTemp2:$Temp2\nTemp3:$Temp3\nHumidity:$Humidity\nHumidityTemp:$HumidityTemp\n";
				LogIt("", "\n") if $debug;
				LogIt("Match Found") if $debug;
				return \$data;
		  }
		  LogIt("chop but no sauce [$char]") if $debug;
	  }
  }
}

sub requestData {
	LogIt("requestData") if $debug;
	sleep 2;
	$port->write("1");
}

sub CacheResults {
	LogIt("CacheResults") if $debug;
	my $cachefile = shift;
	my $data = shift;
	CacheData( $cachefile, $data) ;
}

sub ReadFile {
	my $filename = shift;
	my @Lines;
	if ( ! -e $filename ) {
		LogError("File does not exist [$filename]");
	}
	open(my $input_file, '<', "$filename") or LogError("an error occured reading file: $!");
	flock($input_file, LOCK_SH);
	while (<$input_file>) {
		chomp;
		push @Lines, $_;
	}
	close($input_file);
	flock($input_file, LOCK_UN);
	return (\@Lines); # return an array ref
}

sub CacheData {
	my $cache_file_name = shift;
	my $data = shift;
	my $cachedir = dirname($cache_file_name);
	if ( ! -e $cachedir ) {
		LogError("Cachedir does not exist [$cachedir]");
	}
	LogIt("Creating new Cache File [$cache_file_name]") if $debug;
	open( my $output_file, '>', $cache_file_name ) or LogError("an error occured writing file [$cache_file_name]: $!");
	flock($output_file, LOCK_EX);
	print $output_file $$data;
	flock($output_file, LOCK_UN);
	close $output_file;
	return 1;
}

sub FileAge {
	my $cache_file_name = shift;
	my $maxage = shift;
	my $cachedir = dirname($cache_file_name);

	if ( ! -e $cache_file_name ) {
		return 0;
	}
	if ( ! -e $cachedir ) {
		LogError("Cachedir does not exist [$cachedir]");
	}
	my $fileage = ( time - stat($cache_file_name)->mtime );

	return $fileage;
}

sub LogIt {
	my $now = localtime;
	my $msg = shift;
	my $terminator = shift;
	my $logline;
	my $lastreturncode;
	if ( ! defined $terminator ) { 
		$terminator = "\n";
	  $lastreturncode = $? << 8;
		$logline = "$0:$lastreturncode:$now:$msg$terminator";
	}
	else {
		$logline = "$msg$terminator";
	}
	open(my $log, ">>$LOGFILE") or die "Could not open log to write: $!";
	print $log $logline;
	close($log);
}


sub ClearLog {
	my $now = localtime;
	my $msg = shift;
	my $lastreturncode = $? << 8;
	open(my $log, ">$LOGFILE") or die "Could not open log to write: $!";
	print $log "$0:$lastreturncode:$now:$msg\n";
	close($log);
}

sub LogError {
	my $msg = shift;
	my $lastreturncode = $? << 8;
	print "$0:$lastreturncode:ERROR:$msg\n";
	exit 1;
}

sub DropPrivs {
	my $user = shift;
	if (getuid() == 0) {
		my $Zuid = getpwnam($user);
		print "Dropping Root privs\n" if $debug;
		setuid($Zuid);
	}
}
