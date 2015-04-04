#!/usr/bin/perl
use strict;
use Data::Dumper qw(Dumper);
use File::Basename qw(fileparse);
use File::Remove qw(remove);
use Getopt::Long qw(GetOptions);

validate_environment();

my %state_order = (
    1 => 'fq',
    2 => 'bam',
    3 => 'bam.adam',
    4 => 'vcf.adam',
    5 => 'vcf',
    );
my %state_valid = map {$state_order{$_} => $_} keys %state_order;
my @suffixes = values %state_order;

my %o = (
    'begin'     => 'fq',
    'end'       => 'vcf',
    'aligner'   => 'bwa',
    'cleanup'   => 0,
    'overwrite' => 0,
    );

GetOptions (\%o,
    'begin=s',
    'end=s',

    'cleanup',
    'overwrite',

    'fastq=s',
    'fasta=s',
    'bam=s',

    'aligner=s',
    'avocado-conf=s',
    );

validate_options();

my $current_state = $state_valid{ $o{ 'begin' } };
warn "begin: $o{begin}";
warn "state_order: $state_order{ $current_state }";
warn "state_valid: $state_valid{ $state_order{ $current_state } }";
while ( exists( $state_valid{ $state_order{ $current_state } } ) ) {
  warn "current_state: $current_state";
  if ( $state_order{ $current_state } eq 'bam' ) {
    my ($basename,$path,$suffix) = fileparse( $o{ 'bam' }, @suffixes );

    my $outpath = $basename . $state_order{ $current_state+1 };

    if ( ! $o{ 'overwrite' } && -e $outpath ) {
      print STDERR "Path '$outpath' already exists, use --overwrite to overwrite it.\n" and exit(1);
    }
    else {
      if ( -e $outpath ) {
        remove( \1, $outpath ) or ( print STDERR "Could not remove '$outpath': $!" and exit(1) );
      }
      system( $ENV{ 'ADAM_HOME' } . '/bin/adam-submit' . ' ' .
          'transform' . ' ' .
          $o{ 'bam' } . ' ' .
          $outpath
          );
    }
  }
  $current_state++;
}

sub validate_options() {
  if ( !exists( $state_valid{ $o{ 'begin' } } ) ) {
    print STDERR "Invalid begin step.\n" and exit(1);
  }
  if ( !exists( $state_valid{ $o{ 'end' } } ) ) {
    print STDERR "Invalid end step.\n" and exit(1);
  }

  if ( $o{ 'end' } eq $o{ 'begin' } ) {
    print STDERR "No action required, begin state is the same as end state.\n" and exit(1);
  }

  if ( $o{ 'bam' } && ! -e $o{ 'bam' } ) {
    print STDERR "bam specified does not exist.\n" and exit(1);
  }

  #TODO make sure begin < end in @steps
  #TODO make sure fastq exists, if specified
  #TODO make sure fasta exists, if specified
  #TODO make sure aligner exists, if specified
  #TODO make sure avocado-conf is specified if vcf is a traversed step
  #TODO make sure avocado-conf exists, if specified
}

sub validate_environment() {
  #sanity check for Java
  if ( ! -e $ENV{ JAVA_HOME } ) {
    print STDERR "\$JAVA_HOME must be defined.\n" and exit(1);
  }
  #sanity check for Spark
  if ( ! -e $ENV{ SPARK_HOME } ) {
    print STDERR "\$SPARK_HOME must be defined.\n" and exit(1);
  }
  #sanity check for ADAM
  if ( ! -e $ENV{ ADAM_HOME } ) {
    print STDERR "\$ADAM_HOME must be defined.\n" and exit(1);
  }
  if ( ! -e $ENV{ ADAM_HOME } . "/bin/adam-submit" ) {
    print STDERR "adam-submit not found.  Did ADAM build successfully?\n" and exit(1);
  }
  if ( ! -e $ENV{ ADAM_HOME } . "/bin/adam-shell" ) {
    print STDERR "adam-shell not found.  Did ADAM build successfully?\n" and exit(1);
  }
  #sanity check for Avocado
  if ( ! -e $ENV{ AVOCADO_HOME } ) {
    print STDERR "\$AVOCADO_HOME must be defined.\n" and exit(1);
  }
  if ( ! -e $ENV{ AVOCADO_HOME } . "/bin/avocado-submit" ) {
    print STDERR "avocado-submit not found.  Did Avocado build successfully?\n" and exit(1);
  }
}
