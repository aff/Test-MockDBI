# $Id: fetchall_hashref-many.t 236 2008-12-04 10:28:12Z aff $

use strict;				
use warnings;				

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

use Data::Dumper;
use Test::More;

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local version of Test::MockDBI
use Test::MockDBI;			

plan tests => 4;

# ------ define variables
my $dbh = "";                                      # mock DBI database handle
my $md  = Test::MockDBI::get_instance();
#my $hashref = undef;

# ------ set up return values for DBI fetchrow_hashref() methods
my $arrayref = [
  { key1line1 => 'value1', key2line1 => 'value2' },
  { key1line2 => 'value3', key2line2 => 'value4' },
  { key1line3 => 'value5', key2line3 => 'value6' },
];
$dbh = DBI->connect("", "", "");
$md->set_retval_scalar(
	# Return the array ref containing hash refs, and clear it
  2, "FETCHALL_HASHREF", sub { my $rv = $arrayref; undef $arrayref; return $rv; }
);

$dbh->prepare("FETCHALL_HASHREF");

# first call 
my $arref = $dbh->fetchall_hashref();
ok($arref, q{Expect fetchall_hashref to return true for first row});
isa_ok($arref, q{ARRAY},
  q{Expect fetchall_hashref to return a ARRAY ref (containing HASH refs)})
  or diag(q{arref:} . Dumper($arref));

is_deeply(
  $arref,[
  { key1line1 => 'value1', key2line1 => 'value2' },
  { key1line2 => 'value3', key2line2 => 'value4' },
  { key1line3 => 'value5', key2line3 => 'value6' },],
  q{Expect key value pairs line 1}
);

# second call
$arref = $dbh->fetchall_hashref();
ok(!$arref, q{Expect fetchall_hashref to return false the second time}) or 
	diag(q{rv:}.Dumper($arref));

__END__


