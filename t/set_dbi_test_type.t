# Test set_dbi_test_type().

# $Id: set_dbi_test_type.t 236 2008-12-04 10:28:12Z aff $

# ------ use/require pragmas
use strict;                             # better compile-time testing
use warnings;                           # better run-time warnings
use File::Spec::Functions;
use lib catdir qw ( blib lib );                     # use local Test::MockDBI;
use Test::MockDBI;                      # module we are testing
use Test::More tests => 10;             # advanced testing object


# ------ DBI testing type default is 0 (zero)
is(Test::MockDBI::get_dbi_test_type(), 0,
 "DBI testing type default is 0 (zero)");


# ------ no argument
Test::MockDBI::set_dbi_test_type();
is(Test::MockDBI::get_dbi_test_type(), 0,
 "no argument");


# ------ undef argument
Test::MockDBI::set_dbi_test_type(undef);
is(Test::MockDBI::get_dbi_test_type(), 0,
 "undef argument");


# ------ simple non-digit-string argument
Test::MockDBI::set_dbi_test_type("a");
is(Test::MockDBI::get_dbi_test_type(), 0,
 "simple non-digit-string argument");


# ------ leading non-digit-string argument
Test::MockDBI::set_dbi_test_type("a4");
is(Test::MockDBI::get_dbi_test_type(), 0,
 "leading non-digit-string argument");


# ------ trailing non-digit-string argument
Test::MockDBI::set_dbi_test_type("4a");
is(Test::MockDBI::get_dbi_test_type(), 0,
 "trailing non-digit-string argument");


# ------ middle non-digit-string argument
Test::MockDBI::set_dbi_test_type("4a2");
is(Test::MockDBI::get_dbi_test_type(), 0,
 "middle non-digit-string argument");


# ------ 0 (zero) argument
Test::MockDBI::set_dbi_test_type(0);
is(Test::MockDBI::get_dbi_test_type(), 0,
 "0 (zero) argument");


# ------ 1 (one) argument
Test::MockDBI::set_dbi_test_type(1);
is(Test::MockDBI::get_dbi_test_type(), 1,
 "1 (one) argument");


# ------ other digit string argument
Test::MockDBI::set_dbi_test_type(42);
is(Test::MockDBI::get_dbi_test_type(), 42,
 "other digit string argument");

__END__
