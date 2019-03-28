#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
 
my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->default_header( 'Accept' => 'application/json' );

my $USAGE = <<"__USAGE__";
Usage: 

    $0 <CATH FunFam assignment> <CATH version> <OUTDIR>

    E.g. $0 2.40.50.140/FF/58874 v4_2_0 <outdir_full_path>
	
__USAGE__

my ($cath_assignment, $version, $outdir) = @ARGV;

if( scalar @ARGV != 3) {
	print $USAGE;
	exit;
}
unless($cath_assignment=~ /^(\d\.\d+\.\d+\.\d+)\/FF\/(\d+)/ || $version=~ /^v4\_\d\_\d/){
	print $USAGE;
	exit;
}

$cath_assignment=~ /^(\d\.\d+\.\d+\.\d+)\/FF\/(\d+)$/;
my $cath_superfamily_ID=$1;
my $cath_funfam_ID = $2;

my $funfam_alnfile = "$outdir/$cath_superfamily_ID.$cath_funfam_ID.sto.aln";
open(ALN, ">$funfam_alnfile") or die "Can't open file $funfam_alnfile\n";

my $funfam_GOanno = "$outdir/$cath_superfamily_ID.$cath_funfam_ID.GO.anno";
open(GO, ">$funfam_GOanno") or die "Can't open file $funfam_GOanno\n";
print GO "FUNFAM_RELATIVE/DOMAIN_RANGE        GO_ANNOTATIONS\n";

my $funfam_ECanno = "$outdir/$cath_superfamily_ID.$cath_funfam_ID.EC.anno";
open(EC, ">$funfam_ECanno") or die "Can't open file $funfam_ECanno\n";
print EC "FUNFAM_RELATIVE/DOMAIN_RANGE        EC_ANNOTATIONS\n";

my $url = "http://www.cathdb.info/version/$version/superfamily/$cath_superfamily_ID/funfam/$cath_funfam_ID/files/stockholm";

my $aln;
my $response = $ua->get( $url );
 
if ( $response->is_success ) {
	print ALN $response->decoded_content;
	close ALN;
	my $golines = `fgrep "GO;" $funfam_alnfile`;
	$golines=~ s/#=GS //g;
	$golines=~ s/DR GO; //g;
	print GO $golines;
	close GO;
	my $eclines = `fgrep "EC;" $funfam_alnfile`;
	$eclines=~ s/#=GS //g;
	$eclines=~ s/DR EC; //g;
	print EC $eclines;
	close EC;
	print "The following result files are available here:\n\t$funfam_alnfile\n\t$funfam_GOanno\n\t$funfam_ECanno\n";
}
else {
	die $response->status_line;
}






