#!/usr/bin/perl

use Fcntl qw(:flock);

$lockPath=$ARGV[0];
$clusterPath=$ARGV[1];
$line=$ARGV[2];

open my $lockFile, ">", "$lockPath" or die $!;
flock($lockFile, LOCK_EX) or die "Unable to lockfile $!";
{
	open my $clusterFile, ">>", "$clusterPath" or die "error opening clusterfile $!";
	print $clusterFile $line;
}
flock($lockFile, LOCK_UN) or die "Cannot unlock lockfile - $!";
close($lockFile);
