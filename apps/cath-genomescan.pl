#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Getopt::Long;

# non-core modules
use lib "$FindBin::Bin/../lib";
use Path::Tiny;
use Capture::Tiny qw/ capture /;

my $datadir    = exists $ENV{CATHSCAN_DATADIR} ? $ENV{CATHSCAN_DATA}   : path( $FindBin::Bin, "..", "data" );
my $bindir     = exists $ENV{CATHSCAN_BINDIR}  ? $ENV{CATHSCAN_BINDIR} : path( $FindBin::Bin, "..", "bin" );

my $hmmsearch   = path( $bindir, 'hmmer3', 'hmmsearch' );
my $resolvehits = path( $bindir, 'cath-resolve-hits' );

my $hmmlib = exists $ENV{CATHSCAN_HMMLIB}  ? $ENV{CATHSCAN_HMMLIB} :  path( $datadir, "funfam.hmm3.lib" );

my $PROGRAM_NAME = path($0)->basename;
my $USAGE = <<"__USAGE__";

Usage: $PROGRAM_NAME -i <fasta_file> -l <hmm_lib> -o <output_dir>

Example:

  $PROGRAM_NAME -i ./data/test.fasta -l ./data/cath.funfam.hmm.lib -o results/

__USAGE__

if ( ! scalar @ARGV ) {
 print $USAGE;
 exit;
} 

my $input_file;
my $hmmlib_file;
my $output_dir  = "results.$$";
my $show_html = 1;
my $verbosity = 1;

GetOptions( 
  'in|i=s'     => \$input_file,
  'hmmlib|l=s' => \$hmmlib_file,
  'outdir|o=s' => \$output_dir,
  'html|h'     => \$show_html,
  'verbose|v'  => sub { $verbosity++ },
);

die "! Error: fasta file '$input_file' does not exist"
  unless -s $input_file;

my $cwd = Path::Tiny->cwd;

$input_file  = path( $input_file )->absolute;
$hmmlib_file = path( $hmmlib_file )->absolute;
$output_dir  = path( $output_dir )->absolute;

my $input_filename = $input_file->basename;
$input_filename =~ s/^(.*)\.[^.]*?$/$1/;
my $domtblout_file = $output_dir->path( "$input_filename.domtblout" );
my $crh_file = $output_dir->path( "$input_filename.crh" );
my $html_file = $output_dir->path( "$input_filename.html" );

my $HR = '-' x 78;

INFO( $HR );
INFO( "PROGRAM:         " . path($0)->absolute );
INFO( "DATE:            " . localtime() );
INFO( "PROJECT_HOME:    " . $cwd );
INFO( "QUERY_SEQUENCES: " . $input_file );
INFO( "HMM_LIBRARY:     " . $hmmlib_file );
INFO( "RESULTS_DIR:     " . $output_dir );
INFO( $HR );

if ( ! -d $output_dir ) {
  INFO( "Creating new results directory: $output_dir" );
  mkdir $output_dir
    or die "! Error: failed to create results directory $output_dir: $!\n";
}

INFO( "Processing '$input_file' ..." );

# Run HMMSEARCH to get HMMER3 OUTPUT
INFO( "Scanning HMM library ... (output: $domtblout_file)" );
run_command( $hmmsearch, '--cut_tc', '--domtblout', $domtblout_file, $hmmlib_file, $input_file );

# Run cath-resolve-hits to get CATH DOMAIN ASSIGNMENTS
INFO( "Resolving domain boundaries ... (output: $crh_file)" );
run_command( $resolvehits, 
  '--input-format', 'hmmer_domtblout', 
  '--output-file', $crh_file,
  $domtblout_file );

if ( $show_html ) {
  INFO( "Generating web pages for results ... (output: $html_file)" );
  run_command( $resolvehits, 
    '--input-format', 'hmmer_domtblout',
    '--html-output',
    '--output-file', $html_file,
    $domtblout_file );  
  INFO( "Point your web browser at: file:///$html_file" );
}

INFO( "Done" );

sub run_command {
  my @args = @_;
  my $command = join( " ", @args );
  DEBUG( "CMD: `$command`" );
  my ($stdout, $stderr, $exit) = capture {
    system(@args);
  };
  if ( $exit != 0 ) {
    die "! Error: encountered an error when running command $command (non-zero exit code: $exit)\n"
       . "STDOUT: " . substr( $stdout, 0, 200 ) . "...\n\n"
       . "STDERR: " . substr( $stderr, 0, 200 ) . "...\n\n";
  }
  return ($stdout, $stderr, $exit);
}

sub DEBUG {
  return if $verbosity < 2;
  my $str = "@_";
  chomp( $str );
  print "## $str\n";  
}

sub INFO {
  return if $verbosity < 1;
  my $str = "@_";
  chomp( $str );
  print "# $str\n";
}
