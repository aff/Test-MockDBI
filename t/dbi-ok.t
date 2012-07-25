# Test that DBI works OK when Test::MockDBI is used but not invoked.

# $Id: dbi-ok.t 236 2008-12-04 10:28:12Z aff $

# ------ use/require pragmas
use strict;                 # better compile-time checking
use warnings;               # better run-time checking

use Test::More;
use DBI;                    # database interface

use File::Spec::Functions;
use lib catdir qw ( blib lib );         # use local copy of Test::MockDBI
use Test::MockDBI;          # Test DBI with Test::MockObject

my $config = q{DBI.cfg};
my $hr     = undef;

if (-f $config and -r $config) {
  $hr = get_args($config);
  if (  $hr->{DSN} ne q{}
    and $hr->{USER} ne q{}
    and $hr->{PASS} ne q{}
    and $hr->{SQL}  ne q{})
  {
    plan tests => 2;
  }
  else {
    plan skip_all => qq{File '$config' contains empty configuration data};
  }
}
else {
  plan skip_all => qq{File '$config' does not exists or is unreadable};
}


# ------  get DBI parameters for testing
sub get_args {
  my $file = shift;
  my $ifh  = undef;    # current input file handle
	open($ifh, "<", $file) || die "cannot open DBI.cfg: $!\n";
	my $dsn = <$ifh>;
	chomp($dsn);
	$dsn =~ m/^\w+\s+(.*)/;
	$dsn = $1;
	my $user = <$ifh>;
	chomp($user);
	$user =~ m/^\w+\s+(.*)/;
	$user = $1;
	my $pass = <$ifh>;
	chomp($pass);
	$pass =~ m/^\w+\s+(.*)/;
	$pass = $1;
	my $sql  = <$ifh>;
	chomp($sql);
	$sql =~ m/^\w+\s+(.*)/;
	$sql = $1;
	close($ifh);
  return { DSN => $dsn, USER => $user, PASS => $pass, SQL => $sql };
}

# ------ get a row from the database: must have 1+ columns with 1st column defined 

diag(qq{Connecting to }. $hr->{DSN} . q{ user } . $hr->{USER});
my $dbh = DBI->connect($hr->{DSN}, $hr->{USER}, $hr->{PASS})
 || die "cannot connect to " .$hr->{DSN} .  ": " . DBI::errstr() . "\n";
my $array = $dbh->selectrow_arrayref($hr->{SQL});
cmp_ok(scalar(@$array), q{>}, 0, q{Expect at least one row returned});
ok(defined($array->[0]), q{Expect first element to be defined})

__END__

=pod

=head1 TEST COMMENTS 

This test will only be invoked if the user enters all fields in the
DBI.cfg file. 

=head1 SAMPLE DBI.cfg FILE

 DSN  DBI:mysql:test
 USER dbuser
 PASS secret
 SQL  select t from t

=cut 
