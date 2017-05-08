#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec;
use File::Basename qw/ fileparse basename /;
use FindBin;
use Getopt::Long;
use lib "$FindBin::Bin/../lib/perl5";

my $datadir    = exists $ENV{CATHSCAN_DATADIR} ? $ENV{CATHSCAN_DATA}   : File::Spec->catfile( $FindBin::Bin, "..", "data" );
my $bindir     = exists $ENV{CATHSCAN_BINDIR}  ? $ENV{CATHSCAN_BINDIR} : File::Spec->catfile( $FindBin::Bin, "..", "bin" );

my $hmmsearch   = File::Spec->catfile( $bindir, 'hmmer3', 'hmmsearch' );
my $resolvehits = File::Spec->catfile( $bindir, 'cath-resolve-hits' );

my $hmmlib = exists $ENV{CATHSCAN_HMMLIB}  ? $ENV{CATHSCAN_HMMLIB} :  File::Spec->catfile( $datadir, "funfam.hmm3.lib" );

my $input_file;
my $hmmlib_file;
my $output_dir  = "results.$$";

GetOptions( 
  'in|i=s'     => \$input_file,
  'hmmlib|l=s' => \$hmmlib_file,
  'outdir|o=s' => \$output_dir,
);

my $PROGRAM_NAME = basename($0);
my $USAGE = <<"__USAGE__";

Usage: $PROGRAM_NAME -i <fastafile> -l <hmmlib> -o <output_dir>

Example:

  $PROGRAM_NAME -i ./data/test.fasta -l ./data/cath.funfam.hmm.lib -o results/

__USAGE__

if ( scalar @ARGV != 2 ) {
 print $USAGE;
 exit;
} 

die "! Error: fasta file '$input_file' does not exist"
  unless -s $input_file;

my $input_filename = fileparse($input_file, qr/\.[^.]*/);
  print "Processing $input_filename ...\n";

if ( ! -d $output_dir ) {
  print "Creating new results directory: $output_dir";
  mkdir $output_dir
    or die "! Error: failed to create results directory $output_dir: $!\n";
}

my $output_file = "$input_filename.funfam.domtblout";
my $domain_assignments = "$input_filename.funfam.dom_assignments";

# Run HMMSEARCH to get HMMER3 OUTPUT
run_command( $hmmsearch, '--cut_tc', '--domtblout', $output_file, $hmmlib_file, $input_file );

# Run cath-resolve-hits to get CATH DOMAIN ASSIGNMENTS
run_command( $resolvehits, '--input-format', 'hmmer_domtblout', '--output-file', $domain_assignments, $output_dir );

print "Done\n";

sub run_command {
  my @args = @_;
  my $command = join( " ", @args );
  print "Running `$command` ...\n";
  my ($stdout, $stderr, $exit) = capture {
    system(@args);
  };
  if ( $exit != 0 ) {
    die "! Error: encountered an error when running command $command (non-zero exit code: $exit)\n"
       . "STDOUT: " . substr( $stdout, 0, 200 ) . "...\n\n"
       . "STDERR: " . substr( $stdout, 0, 200 ) . "...\n\n";
  }
  return ($stdout, $stderr, $exit);
}
