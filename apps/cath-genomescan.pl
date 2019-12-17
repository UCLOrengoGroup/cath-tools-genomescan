#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Getopt::Long;
use Config;

# non-core modules
use lib "$FindBin::Bin/../lib/perl5";
use Path::Tiny;
use Capture::Tiny qw/ capture /;

$| = 1;

my $datadir    = exists $ENV{CATHSCAN_DATADIR} ? $ENV{CATHSCAN_DATA}   : path( $FindBin::Bin, "..", "data" );
my $bindir     = exists $ENV{CATHSCAN_BINDIR}  ? $ENV{CATHSCAN_BINDIR} : path( $FindBin::Bin, "..", "bin" );

my $bintype     = $Config{osname} eq 'darwin' ? 'macos' : 'centos6';
my $hmmsearch   = path( $bindir, 'hmmer3', 'hmmsearch' );
my $resolvehits = path( $bindir, "cath-resolve-hits.$bintype" );
my $min_dc_hmm_coverage = 80;
my $max_seq_db_size = 10_000_000;

if ( ! -e $resolvehits ) {
  die "! Error: failed to find cath-resolve-hits binary: $resolvehits (this should not happen, please raise an issue on github)";
}

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
my $hmmsearchout_file = $output_dir->path( "$input_filename.hmmsearch" );
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

INFO( "Processing data ..." );
my $input_sequences = count_fasta_sequences( $input_file );
INFO( "  ... found $input_sequences sequences" );
my $hmm_models = count_hmm_models( $hmmlib_file );
INFO( "  ... found $hmm_models HMM models" );
INFO();


# Run HMMSEARCH to get HMMER3 OUTPUT
my $hmm_counter = 0;
my $partition_count = 10;
my $partition_size = sprintf( "%d", 1 + ($hmm_models / $partition_count) ) || 1;
my $stdout_processor = sub {
  my $line = $_[0];
  chomp($line);
  if ( $line =~ /^Query:/ ) {
    if ( $hmm_counter % $partition_size == 0 ) {
      INFO( sprintf "  progress: %3d%% (%d of %d hmms)",
        100 * $hmm_counter / $hmm_models,
        $hmm_counter, $hmm_models
      );
    }
    $hmm_counter++;
  }
};

INFO( "Scanning HMM library ..." );
INFO( "  output: $domtblout_file" );
run_command( $hmmsearch, [
    '--cut_tc',
    '--domtblout', $domtblout_file,
    '-Z', $max_seq_db_size,
    '-o', $hmmsearchout_file,
    $hmmlib_file,
    $input_file,
  ],
  $stdout_processor );

INFO( "  done" );
INFO();

# Run cath-resolve-hits to get CATH DOMAIN ASSIGNMENTS
INFO( "Resolving domain boundaries ... " );
INFO( "  output: $crh_file" );
run_command( $resolvehits, [
  '--input-format', 'hmmsearch_out',
  '--hits-text-to-file', $crh_file,
  "--min-dc-hmm-coverage=$min_dc_hmm_coverage",
  ( $show_html ? ('--html-output-to-file', $html_file) : () ),
  $hmmsearchout_file,
  ] );
INFO( "  done" );
INFO();

if ( $show_html ) {
  INFO( "Point your web browser at: file://$html_file" );
}

INFO();

INFO( "Done" );

sub run_command {
  my $prog = shift;
  my $args = shift;
  my $stdout_processor = shift;

  my $command = join( " ", $prog, @$args );
  INFO( "CMD: `$command`" );
  my $query_count = 0;
  if ( $stdout_processor ) {
    open(my $fh, "-|", "$command")
      or die "! Error: failed to open pipe to command `$command`: $!";
    while (my $line = $fh->getline) {
      $stdout_processor->($line);
    }
  }
  else {
    my ($stdout, $stderr, $exit) = capture {
      system( $command );
    };
    if ( $exit != 0 ) {
      die "! Error: encountered an error when running command $command (non-zero exit code: $exit)\n"
         . "STDOUT: " . substr( $stdout, 0, 200 ) . "...\n\n"
         . "STDERR: " . substr( $stderr, 0, 200 ) . "...\n\n";
    }
  }
}

# this is not meant to be a sequence parser - just a quick way of getting the number of query sequences
sub count_fasta_sequences {
  my $file = shift;
  my $fh = path( $file )->openr or die "! Error: failed to open input file '$file': $!";
  my $sequence_count = 0;
  while( my $line = $fh->getline ) {
    if ( substr($line, 0, 1 ) eq '>' ) {
      $sequence_count++;
    }
  }
  return $sequence_count;
}

sub count_hmm_models {
  my $hmmlib_file = shift;
  my $fh = path($hmmlib_file)->openr or die "! Error: failed to open hmmlib file: $!";
  my $hmm_count = 0;
  while( my $line = $fh->getline ) {
    if ( $line =~ /^NAME/ ) {
      $hmm_count++;
    }
  }
  return $hmm_count;
}

sub DEBUG {
  return if $verbosity < 2;
  my $str = "@_";
  chomp( $str );
  printf "%s ## %s\n", localtime() . "", $str;
}

sub INFO {
  return if $verbosity < 1;
  my $str = "@_";
  chomp( $str );
  printf "%s # %s\n", localtime() . "", $str;
}
