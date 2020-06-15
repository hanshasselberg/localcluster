#!/usr/bin/perl
# script for splitting multi-cert input into individual certs
# Artistic Licence
#
# v0.0.1         Nick Burch <nick@tirian.magd.ox.ac.uk>
# v0.0.2         Tom Yates <tyates@gatekeeper.ltd.uk>
#

$filename = shift;
unless($filename) {
  die("You must specify a cert file.\n");
}
open INP, "<$filename" or die("Unable to load \"$filename\"\n");

$thisfile = "";

while(<INP>) {
   $thisfile .= $_;
   if($_ =~ /^\-+END(\s\w+)?\sCERTIFICATE\-+$/) {
      print "Found a complete certificate:\n";
      print `echo \'$thisfile\' | openssl x509 -noout -text`;
      $thisfile = "";
   }
}
close INP;
