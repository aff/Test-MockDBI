# $Id: Makefile.PL 283 2009-02-03 12:39:11Z aff $

use strict;
use warnings;

use 5.008;
use ExtUtils::MakeMaker;

# Set PERL_MM_USE_DEFAULT to make prompt use default, or set
# AUTOMATED_TESTING to skip altogether

# ------ get DBI parameters for later testing
if (!-s "DBI.cfg" and !$ENV{AUTOMATED_TESTING}) {
  $| = 1;
  my $dsn  = prompt("DBI data source:",  "");
  my $user = prompt("DBI username:",     "");
  my $pass = prompt("DBI password:",     "");
  my $sql  = prompt("DBI 'SELECT' SQL:", "");
  my $ofh;
  open($ofh, ">", "DBI.cfg") || die "cannot create DBI.cfg: $!\n";
  print $ofh <<"endPRINT";
DSN  $dsn
USER $user
PASS $pass
SQL  $sql
endPRINT
  close($ofh) || die "cannot close DBI.cfg: $!\n";
  chmod(0600, "DBI.cfg");
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'           => 'Test::MockDBI',
  'VERSION_FROM'   => 'lib/Test/MockDBI.pm',
  'ABSTRACT_FROM'  => 'lib/Test/MockDBI.pm',
  'AUTHOR'         => 'Mark Leighton Fisher <mark-fisher@fisherscreek.com>',
  'LICENSE'        => 'perl',
  'BUILD_REQUIRES' => { 'CPAN::Meta' => 0, },
  'PREREQ_PM'      => {
    'DBI'                   => 0,
    'Test::MockObject'      => 0.14,
    'Test::More'            => 0,
    'File::Spec::Functions' => 0,
    'Test::Warn'            => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'Test-MockDBI-*' },
);

__END__
