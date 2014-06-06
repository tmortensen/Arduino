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

my $now = localtime;
my $SERIAL_PORT = '/dev/ttyACM0';
my $max_cache_age = 60; # 1 Minutes
#our $debug = undef;
our $debug = 1;
my $SCRIPT = basename($0);
my $LOGFILE = "/tmp/$SCRIPT.log";
my $CACHE_DIR="/dev/shm";
my $CACHE_FILE=$CACHE_DIR . '/' . 'greenhouse.info';
my $RUNASUSER = 'nobody'; # for DropPrivs($RUNASUSER); 


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

sub getPayload {

	requestData();
	sleep 2;
	while (1) {
# Poll to see if any data is coming in
		my $char = $port->lookfor();
		if ($char) { 
			chop $char;
			#say $char;
			if ($char =~ m/(\d{2}\.\d{2}),(\d{2}\.\d{2}),(\d{2}\.\d{2}),(\d{2}\.\d{2}),(\d{2}\.\d{2})/) {
				my $Temp1 = $1;
				my $Temp2 = $2;
				my $Temp3 = $3;
				my $Humidity = $4;
				my $HumidityTemp = $5;
				my $data = "Temp1:$Temp1\nTemp2:$Temp2\nTemp3:$Temp3\nHumidity:$Humidity\nHumidityTemp:$HumidityTemp";
				$now = localtime;
				say "$now : got chop and sauce [$data]" if $debug;
				return \$data;
			}
			$now = localtime;
			say "$now : chop but no sauce [$char]" if $debug;
		}
	}
}

sub requestData {
	sleep 2;
	$port->write("1");
	sleep 2;
}

sub CacheResults {
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
	LogIt("Creating new Cache File [$cache_file_name] for [$data]") if $debug;
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
  my $msg = shift;
  my $lastreturncode = $? << 8;
  open(my $log, ">>$LOGFILE") or die "Could not open log to write: $!";
  print $log "$0:$lastreturncode:$msg\n";
  close($log);
#print "$0:$lastreturncode:$msg\n";
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





