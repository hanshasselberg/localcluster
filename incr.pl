#!/usr/bin/perl

use Fcntl qw(:flock);

$lockPath=$ARGV[0];
$portPath=$ARGV[1];

open my $lockFile, ">", "$lockPath" or die $!;
flock($lockFile, LOCK_EX) or die "Unable to lockfile $!";
my $port;
{
	open my $portFile, "+<", "$portPath" or die "error opening portfile: $!";
	$port = do { local $/; <$portFile> };
	$port = int($port)+1;
	seek($portFile, 0, 0);
	print $portFile $port;
}
print $port;
flock($lockFile, LOCK_UN) or die "Cannot unlock lockfile - $!";
close($lockFile);
