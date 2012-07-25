package Test::MockDBI;

# Test DBI interfaces using Test::MockObject.

# $Id: MockDBI.pm 283 2009-02-03 12:39:11Z aff $

# ------ use/require pragmas
use 5.008;                              # minimum Perl is V5.8.0
use strict;                             # better compile-time checking
use warnings;                           # better run-time checking
use Data::Dumper;                       # dump data in a pleasing format
use Test::MockObject::Extends;          # mock objects for extending classes
require Exporter;                       # we are an Exporter


# ------ exportable constant
use constant MOCKDBI_WILDCARD => 0;     # DBI type wildcard ("--dbitest=TYPE")


# ------ global variables
our %EXPORT_TAGS                        # named lists of symbols to export
 = ( 'all' => [ qw( MOCKDBI_WILDCARD ) ] );
our @EXPORT_OK                          # symbols to export upon request
 = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();                     # symbols to always export
our @ISA = qw(Exporter);                # we ISA Exporter :)
our $VERSION = '0.66';                  # our version number

# ------ file-global variables
my %array_retval  = ();                 # return array values for matching SQL
my @bad_params    = ();                 # list of bad parameter values
my @bind_columns  = ();                 # bind_columns() list of refs to bind
my @cur_array     = ();                 # current array to return
my $cur_scalar    = undef;              # current scalar to return
my $cur_sql       = "";                 # current SQL
my %fail          = ();                 # hash for methods to fail, why and how
my $fail_param    = 0;                  # TRUE when failing due to bad param
my $instance      = undef;              # my only instance
my $mock          = "";                 # mock DBI object from Test::MockObject::Extends
my $object        = "";                 # our fake DBI object
my %rows_retval   = ();                 # return DBI::rows() values for matching SQL
my %scalar_retval = ();                 # return scalar values for matching SQL
my $type          = 0;                  # DBI testing type from command line
my %errstr        = ();                 # The scalar to return for errors
my $debug         = undef;              # Toggle to enable debugging
my $rollback      = 0;
my $wait_for_commit = 0;
my $commit_rollback_enable = 0;
 


# ------ convert argument to defined value, use "" if undef argument
sub _define {
    my $arg = shift;                    # argument to convert

    if (defined($arg)) {
        return ($arg);
    }
    return "";
}


# ------ return TRUE if SQL matches pattern, handle undef values
sub _sql_match {
    my $sql     = _define(shift);        # SQL
    my $pattern = _define(shift);        # SQL regex string to match

    if (!$sql && !$pattern) {
        return 1;
    }
    if (!$pattern) {
        return 0;
    }
        if ($sql =~ m/$pattern/ms) {
                return 1;
        }
        return 0;
}


# ------ check if this DBI method should fail
sub _fail {
    my $method  = shift;                # method name
    my $spec    = "";                   # method failure specification

    # ------ fail returned data due to bad parameter
    if ($fail_param &&
     ($method =~ m/^fetch/ || $method =~ m/^select/)) {
        $fail_param = 0;
        return 1;
    }

    # ------ no failure modes for this DBI method
    $spec = $fail{$method};
    if (!defined($spec)) {
        return 0;
    }

    # ------ no failure modes for this MockDBI type
    if (!defined($spec->{$type})) {
        return 0;
    }

    # ------ return TRUE if SQL matches
    return _sql_match($cur_sql, $spec->{$type}->{"SQL"});
}


# ------ bind an array to DBI columns bound by bind_columns()
sub _bind_array {
    my $i;                              # generic loop index

    return if (scalar(@bind_columns == 0));

    for ($i = 0; $i < scalar(@bind_columns); $i++) {
        ${$bind_columns[$i]} = $_[$i];
    }
}

# ------ force an array return value
sub _force_retval_array {
    local $_;                           # localized topic
    my @array = ();                     # generic array

    foreach (@{ $array_retval{MOCKDBI_WILDCARD()} }, @{ $array_retval{$type} }) {
        if (_sql_match($cur_sql, $_->{"SQL"})) {
            if (ref($_->{"retval"}) eq "ARRAY"
             && ref($_->{"retval"}->[0]) eq "CODE") {
                @array = &{ $_->{"retval"}->[0] }();
                if (scalar(@array) > 0) {
                    _bind_array(@array);
                }
                return @array;
            }
            @array = @{ $_->{"retval"} };
            _bind_array(@array);

            # Return array ref if first element of array is HASH ref
            if (scalar(@array) && ref($array[0]) eq 'HASH') {
              (defined($array[0])) ? return \@array : return;
            }

            return @array;
        }
    }
    if (scalar(@_) < 1) {
        return ();
    }
    _bind_array(@_);
    return @_;
}


# ------ bind an arrayref to DBI columns bound by bind_columns()
sub _bind_arrayref {
    my $i;                              # generic loop index

    return if (scalar(@bind_columns == 0));
    if (ref($_[0]) ne "ARRAY") {
        for ($i = 0; $i < scalar(@bind_columns); $i++) {
            ${$bind_columns[$i]} = undef;
        }
    }

    for ($i = 0; $i < scalar(@bind_columns); $i++) {
        ${$bind_columns[$i]} = $_[0]->[$i];
    }
}


# ------ force a scalar return value
sub _force_retval_scalar {
    local $_;                           # localized topic
    my $arrayref = "";                  # (probably) generic arrayref

    foreach (@{ $scalar_retval{MOCKDBI_WILDCARD()} }, @{ $scalar_retval{$type} }) {
        if (_sql_match($cur_sql, $_->{"SQL"})) {
            if (ref($_->{"retval"}) eq "CODE") {
                $arrayref = &{ $_->{"retval"} }();
                if (defined($arrayref) && ref($arrayref) eq "ARRAY") {
                    _bind_arrayref($arrayref);
                }
                return $arrayref;
            }
            $arrayref = $_->{"retval"};
            _bind_arrayref($arrayref);
            return $arrayref;
        }
    }
    if (defined($_[0])) {
        _bind_arrayref($_[0]);
    }
    return $_[0];
}


# ------ force a DBI::rows() return value
sub _force_retval_rows {
    local $_;                           # localized topic

    foreach (@{ $rows_retval{MOCKDBI_WILDCARD()} }, @{ $rows_retval{$type} }) {
        if (_sql_match($cur_sql, $_->{"SQL"})) {
            if (ref($_->{"retval"}) eq "CODE") {
                return &{ $_->{"retval"} }();
            }
            return $_->{"retval"};
        }
    }
    return $_[0];
}


# ------ fake the specified DBI method call
sub _fake {
    my $method = shift;                 # file-global method name
    my $arg    = shift;                 # first method arg
    my $retval;                         # scalar to return

    print "\n$method()" if ($debug);
    if (defined($arg)) {
        print " '$arg'" if ($debug);
    }
    print "\n" if ($debug);
    if (_fail($method)) {
      return;
    }

    if ($method eq "rows") {
        $retval = shift;
        return _force_retval_rows($retval);
    } elsif ($method =~ m/^fetch/ || $method =~ m/^select/) {

        
        if ($method eq "fetch"
         || $method eq "fetchrow"
         || $method eq "fetchrow_array"
         || $method eq "selectrow_array") {
            return ( $wait_for_commit && $commit_rollback_enable ) ? '' : _force_retval_array(@_);
        }
        $retval = shift;
        return ( $wait_for_commit && $commit_rollback_enable ) ? '' : _force_retval_scalar($retval);
        
    } elsif($method =~ m/^bind_param_inout/) {
        
        my $temp = undef;                # 1 of @bad_params
        my $arrayref = undef;
        $retval = shift;
        
        $arrayref = $arg->fetchrow_arrayref();                                 
        $temp  = $arrayref;
        
        push(@{$temp}, 'SQLState') if (!grep /SQLState$/i, @{$temp});
        push(@{$temp}, 'SQLCode') if (!grep /SQLCode$/i, @{$temp});  
        push(@$retval, $temp);    
        
     
        foreach my $val (@{$retval->[0]}) {           
            $val = '02000' if ($val eq 'SQLState' && !$arrayref);
            $val = '00000' if ($val eq 'SQLState' && $arrayref);
            
            $val = '+100' if ($val eq 'SQLCode' && !$arrayref);
            $val = '+000' if ($val eq 'SQLCode' && $arrayref); 
        }
    }    

    if ( defined $method && defined $arg && $method =~ /^(prepare|do|prepare_cached)/i  && $arg =~ /^(select)/i ) {        
        $commit_rollback_enable = 0;
        
    }
    # handle Insert or Update or Delete DML operations
    if ( defined $method && defined $arg && $method =~ /^(prepare|do|prepare_cached)/i  && $arg =~ /^(insert|delete|Update)/i ) {        
        $commit_rollback_enable = 1;
        
    }
    
    $retval = shift;
    return $retval;
}


# ------
# ------ Test::MockDBI external methods
# ------


# ------ return the current DBI testing type number
sub get_dbi_test_type {
    return $type;
}


# ------ set the current DBI testing type number
sub set_dbi_test_type {
    $type = shift;
    if (!defined($type) || $type !~ m/^\d+$/) {
        $type = 0;
    }
}


# ------ force a DBI method to be bad
sub bad_method {
    my $self   = shift;                 # my blessed self
    my $method = shift;                 # method name
    my $type   = shift;                 # type number from --dbitest=TYPE
    my $sql    = shift;                 # SQL pattern for badness

    $fail{$method}->{$type}->{"SQL"} = $sql;
    return 1;
}


# ------ set up an array return value for the specified SQL pattern
sub set_retval_array {
    my $self   = shift;                 # my blessed self
    my $type   = shift;                 # type number from --dbitest=TYPE
    my $sql    = shift;                 # SQL pattern for badness
    my $valid = [ $sql ];
    if ( grep { m/^\s*select/i } @$valid ) {
        $commit_rollback_enable = 0;
    }
    push @{ $array_retval{$type} },
     { "SQL" => $sql, "retval" => [ @_ ] },
}


# ------ set up scalar return value for the specified SQL pattern
sub set_retval_scalar {
    my $self   = shift;                 # my blessed self
    my $type   = shift;                 # type number from --dbitest=TYPE
    my $sql    = shift;                 # SQL pattern for badness
    my $valid = [ $sql ];
    if ( grep { m/^\s*select/i } @$valid ) {
        $commit_rollback_enable = 0;
    }
    push @{ $scalar_retval{$type} },
     { "SQL" => $sql, "retval" => $_[0] };
   
}


# ------ set up DBI::rows return value for the specified SQL pattern
sub set_rows {
    my $self   = shift;                 # my blessed self
    my $type   = shift;                 # type number from --dbitest=TYPE
    my $sql    = shift;                 # SQL pattern for badness
    my @Valid = qw( $sql );
    my $valid = [ $sql ];
    if ( grep { m/^\s*select/i } @$valid ) {
        $commit_rollback_enable = 0;
    }
    push @{ $rows_retval{$type} },
     { "SQL" => $sql, "retval" => $_[0] },
}


# ------ force a parameter to be bad
# ------ Returns current number of bad params
sub bad_param {
    my $self      = shift;              # my blessed self
    my $bad_type  = shift;              # type number from --dbitest=TYPE
    my $bad_param = shift;              # "known" bad parameter number
    my $bad_value = shift;              # "known" bad parameter value

    push(@bad_params, [ $bad_type, $bad_param, $bad_value ] );
}

# ------ allow errstr to be set and unset
sub set_errstr {
    my $self      = shift;              # my blessed self
    my $bad_type  = shift;              # type number from --dbitest=TYPE
    my $arg       = shift;              # the argument
    if (defined($arg) && $arg ne '') {
      $errstr{$bad_type} = $arg;
    } else {
      $errstr{$bad_type} = undef;
    }
}

# Return true if given param name and value is bad in given mode,
# otherwise undefined.  Used for testing purposes only.
sub _is_bad_param {
  my $self   = shift;    # my blessed self
  my $type   = shift;    # type number from --dbitest=TYPE
  my $number = shift;    # "known" bad parameter number
  my $value  = shift;    # "known" bad parameter value

  foreach my $param (@bad_params) {
    if ( $param->[0] == $type
      && $param->[1] == $number
      && $param->[2] eq $value)
    {
      return 1;
    }
  }
  return;
}

sub handle_errors {
        
        my $self   = shift;    # my blessed self
        my $errormsg = shift; # the error message
        my $caller = shift || (caller(1))[3]; # the error message
        my $sqlcode = "SQL0100";
        my $sqlstate = "SQLSTATE=02000";
       
        warn "DBI::db $caller failed: $sqlcode $errormsg. $sqlstate\n" if (defined ($self->{PrintError}) && $self->{PrintError} == 1);
        die "DBI::db $caller failed: $sqlcode $errormsg. $sqlstate\n" if (defined ($self->{RaiseError}) && $self->{RaiseError} == 1);
        
}

#
# ------ GLOBAL INITIALIZATION
#
# ------ initialize our instance
$instance = bless {}, "Test::MockDBI";

# ------ set our testing type if we are in test mode
$type = 0;
if ($#ARGV >= 0 && $ARGV[0] =~ m/^--?dbitest(=(\d+))?/) {
    $type = 1;
    if (defined($2)) {
        $type = $2;
    }
    shift;
}

# ------ non-zero type of DBI testing to perform
if ($type) {

    # ------ initialize DBI mock interface
    $mock = Test::MockObject::Extends->new();
    print "mock DBI interface initialized...\n" if ($debug);

    $mock->fake_module("DBI",
     connect =>  sub {
        my $self = shift;
        my $dsn  = _define(shift);
        my $user = _define(shift);
        my $pass = _define(shift);
        my $attr = shift;
      
        $DBI::stderr =  undef; #2_000_000_000;
        my %attributes;
        $object = bless({}, "DBI::db");
        
        %attributes = (
            PrintError => 1,
            RaiseError => 0,
            AutoCommit => 1,
            ref $attr ? %$attr : (),
        );            
       
        while ( my ($a, $v) = each %attributes) {
        	 $object->{$a} = $v ;                
        }
        $object->{BegunWork}    = 0;
        $object->{Errstr}       = undef;
        $object->{Err}          = undef;       
        
        
        $wait_for_commit        = 1 if $object->{AutoCommit} == 0 ;
        $cur_sql = "CONNECT TO $dsn AS $user WITH $pass";
        $fail_param = 0;
        @bind_columns = ();
       
        return _fake("connect", $cur_sql, $object) or handle_errors($object,"$self connect ($dsn) failed", "connect");
     },
     
     errstr =>  sub {
        my $self = shift;
        $DBI::stderr = "Could not make fake connection\n";
        return $DBI::stderr if defined $DBI::stderr;
        return _fake("errstr", $_[0], $errstr{$type});
     },
     err =>  sub {
        my $self = shift;
        $DBI::stderr = "DB Engine Native Error Code - Could not make fake connection\n";
        return $DBI::stderr if defined $DBI::stderr;
        return _fake("errstr", $_[0], $errstr{$type});
     },
    );
    
    $mock->fake_module( "DBI::db",
     ping =>  sub {
        my $self = shift;
        return _fake("ping", $_[1], 1) or handle_errors($self,"Unable to ping", "ping");
     },
     disconnect =>  sub {
        my $self = shift;
        $cur_sql = "DISCONNECT";
        $fail_param = 0;
        @bind_columns = ();
        return _fake("disconnect", $_[1], 1) or handle_errors($self,"Unable to ping", "disconnect");
     },
     errstr =>  sub {
        my $self = shift;
        $self->{Errstr} = $DBI::stderr;
        return $self->{Errstr} if defined $self->{Errstr};#DBI->errstr;
        return _fake("errstr", $_[0], $errstr{$type});
     },
     err =>  sub {
        my $self = shift;
        $self->{Err} = $DBI::stderr;
        return $self->{Err};# if defined $self->{Err};#DBI->errstr;
        return _fake("errstr", $_[0], $errstr{$type});
     },
     prepare =>  sub {
        my $self =shift;
        $cur_sql = shift;
        $cur_sql = _define($cur_sql);
        $fail_param = 0;
        @bind_columns = ();
        
        unless ( $cur_sql =~ /\w+/ ) {
            $DBI::stderr = "Could not prepare, Please check the SQL query";
            handle_errors($self,"Could not prepare", "prepare");
        }
        
        
        return _fake("prepare", $cur_sql, $object);
     },
     prepare_cached =>  sub {
        
        $cur_sql = _define($_[1]);
        $fail_param = 0;
        @bind_columns = ();
        
        unless ( $cur_sql =~ /\w+/ ) {
            $DBI::stderr = "Could not prepare, Please check the SQL query";
            handle_errors($object,"Could not prepare", "prepare_cached");
        }
        
        return _fake("prepare_cached", $_[1], $object);
     },
     commit =>  sub {
        my $self  = shift;
        
        if ( defined($self->{AutoCommit}) && $self->{AutoCommit} == 1){
            $DBI::stderr = "Cannot commit when AutoCommit is on";
            warn $DBI::stderr;
            handle_errors($object,"Cannot commit when AutoCommit is on", "commit");
            return 1;
        }
        
        if ( $commit_rollback_enable ){
            $wait_for_commit = $rollback ? 1 : 0 ;
            $self->{AutoCommit} = 1 if ($self->{BegunWork} == 1);
            $self->{BegunWork} = 0;           
        }
        return _fake("commit", $_[0], 1) or handle_errors($object,"Commit failed", "commit");
     },
     bind_columns =>  sub {
        shift;
        unless(scalar(@_)) {
            handle_errors($object,"There are no columns for binding", "bind_columns");
        }
        @bind_columns = @_;        
        return _fake("bind_columns", $_[0], 1) or handle_errors($object,"Binding failed", "bind_columns");
     },
     bind_param => sub {
        # Return 1 if param bound was good, otherwise -1 (still true,
        # but indicates badness)

        my $self         = shift;             # my blessed self
        my $param        = _define(shift);    # parameter number
        my $value        = shift;             # parameter value
        my $attr_or_type = _define(shift);    # attributes or type
        my $bad_param    = "";                # 1 of @bad_params

        print "\nbind_param()\n" if ($debug);
        print "parm $param, value " if ($debug);
        
        print Dumper($value);
        
        if ($attr_or_type) {
            if (ref($attr_or_type) eq "HASH") {
                print "  attrs ", Dumper($attr_or_type) if ($debug);
            } else {
                print "type '$attr_or_type'" if ($debug);
            }
        }
        print "\n" if ($debug);
        if (_fail("bind_param")) {
           return;
        }
        ## no critic (RequireLexicalLoopIterators)
        foreach $bad_param (@bad_params) {
            if ($bad_param->[0] == $type
             && $bad_param->[1] == $param
             && $bad_param->[2] eq $value) {
                print "MOCK_DBI: BAD PARAM $param = '$value'\n" if ($debug);
                handle_errors($object,"MOCK_DBI: BAD PARAM $param = '$value'", "bind_param");
                $fail_param = 1;
                return -1;  # Indicate that param is bad
            }
        }
        return 1;
     },
     bind_param_inout => sub {
               
        my $self        = shift;             # my blessed self
        my $params       = _define(shift);    # parameter number
        my $ref_value   = shift;             # Reference of bind value
        
        my $max_len     = _define(shift);    # Min. amount of memory to allocate to bind value
        
        unless ( ref $ref_value ~~ /ARRAY/) {
            $DBI::stderr = "The return paramater must be array reference";
            handle_errors($self,"The return parameter must be array reference", "bind_param_inout");
            return;
        }
        
        return _fake("bind_param_inout", $self, $ref_value) or handle_errors($self,"Binding failed", "bind_param_inout");
        
     },
     do =>  sub {
        my $self        = shift;             # my blessed self
        my $params       = _define(shift);    # parameter number
        unless ( $params =~ /\w+/) {
            $DBI::stderr = "Expect SQL query";
            handle_errors($self,"Expect SQL query", "do");
            return;
        }
        return _fake("do", $_[1], 1);
     },
     execute =>  sub {
        return _fake("execute", $_[1], 1) or handle_errors($object,"Execute failed", "execute");
     },
     finish =>  sub {
        $fail_param = 0;
        return _fake("finish", $_[1], 1) or handle_errors($object,"Finish failed", "finish");
     },
     fetchall_arrayref =>  sub {
        return _fake("fetchall_arrayref", $_[1], undef) or handle_errors($object,"Fetch all array reference failed", "fetchall_arrayref");
     },
     fetchrow_arrayref =>  sub {
        return _fake("fetchrow_arrayref", $_[1], undef) or handle_errors($object,"Fetch row array reference failed", "fetchrow_arrayref");
     },
     fetchrow_hashref =>  sub {
        return _fake("fetchrow_hashref", $_[1], undef) or handle_errors($object,"Fetch row hash reference failed", "fetchrow_hashref");
     },
     fetchall_hashref =>  sub {
        return _fake("fetchall_hashref", $_[1], undef) or handle_errors($object,"Fetch all hash reference failed", "fetchall_hashref");
     },
     fetchrow_array =>  sub {
        return _fake("fetchrow_array", $_[1]) or handle_errors($object,"Fetch row array failed", "fetchrow_array");
     },
     fetchrow =>  sub {
        return _fake("fetchrow", $_[1]) or handle_errors($object,"Fetch row failed", "fetchrow");
     },
     fetch =>  sub {
        return _fake("fetch", $_[1]) or handle_errors($object,"Fetch failed", "fetch");
     },
     rows =>  sub {
        return _fake("rows", $_[1], 0) or handle_errors($object,"Rows failed", "rows");
     },
     begin_work => sub {
        my $self = shift;
        $self->{AutoCommit} = 0;
        $wait_for_commit = 1;
        $self->{BegunWork} = 1;
        return _fake("begin_work", $_[1], 0) or handle_errors($self,"Begin work unable to set", "begin_work");
     },
     rollback => sub {
        my $self  = shift;       
        if ( $self->{AutoCommit} == 1){
                $DBI::stderr = "Cannot rollback when AutoCommit is on";
                warn $DBI::stderr;
                handle_errors($self,"Cannot rollback when AutoCommit is on", "rollback");
                return 1;
        }
        if ( $commit_rollback_enable ){
            $rollback = 1;
            $self->{AutoCommit} = 1 if ($self->{BegunWork} == 1);
            $self->{BegunWork} = 0;           
        };
         return _fake("rollback", $_[0], 1) or handle_errors($self,"Rollback failed", "rollback");
     },
    );
    $mock->fake_new("DBI");
}



# ------ return our instance, as we are a singleton class
sub get_instance {
  $debug = shift;
  $rollback = 0;
  $wait_for_commit = 0;
  $commit_rollback_enable = 0;
  return $instance;
}


1;

__END__


=head1 NAME

Test::MockDBI - Mock DBI interface for testing

=head1 SYNOPSIS

  use Test::MockDBI;
     OR
  use Test::MockDBI qw( :all );

  Test::MockDBI::set_dbi_test_type(42);
  if (Test::MockDBI::get_dbi_test_type() == 42) {
    ...

  $mock_dbi = get_instance Test::MockDBI;

  $mock_dbi->bad_method(
   $method_name,
   $dbi_testing_type,
   $matching_sql);

  $mock_dbi->bad_param(
   $dbi_testing_type,
   $param_number,
   $param_value);

  $mock_dbi->set_retval_array(
   $dbi_testing_type,
   $matching_sql,
   @retval || CODEREF);
  $mock_dbi->set_retval_array(MOCKDBI_WILDCARD, ...

  $mock_dbi->set_retval_scalar(
   $dbi_testing_type,
   $matching_sql,
   $retval || CODEREF);
  $mock_dbi->set_retval_scalar(MOCKDBI_WILDCARD, ...

  $mock_dbi->set_rows(
   $dbi_testing_type,
   $matching_sql,
   $rows || CODEREF);
  $mock_dbi->set_rows(MOCKDBI_WILDCARD, ...

=head1 EXAMPLE

Code: 

  # Enable testing with Test::MockDBI
  BEGIN { push @ARGV, "--dbitest"; }
  use Test::MockDBI qw( :all );
  my $md  = Test::MockDBI::get_instance();
  my $dbh = DBI->connect("", "", "");

  # Set of return values for given sql query
  my $aref_of_hrefs = [
    { name => 'Huey',  instrument => 'cello' },
    { name => 'Dewey', instrument => 'trombone' },
    { name => 'Louie', instrument => 'piano' },
  ];
  $md->set_retval_scalar(
    MOCKDBI_WILDCARD,
    "select name, instrument from nephews",
    sub { shift @$aref_of_hrefs }
  );

  # Execute the sql query and fetch results
  $dbh->prepare("select name, instrument from nephews");
  while (my $href = $dbh->fetchrow_hashref()) {
    print $href->{name} .
          " plays the " .
          $href->{instrument} . "\n";
  }
  __END__

Expected output:

  Huey plays the cello
  Dewey plays the trombone
  Louie plays the piano


=head1 DESCRIPTION

Test::MockDBI provides a way to test DBI interfaces by
creating rules for changing the DBI's behavior, then
examining the standard output for matching patterns.

Testing using Test::MockDBI is enabled by setting
the DBI testing type to a non-zero value.  This can
be done either by using a first program argument
of "--dbitest[=TYPE]", or by using the class method
Test::MockDBI::set_dbi_test_type().  (Supplying a first
argument of "--dbitest[=TYPE]" often works well during
testing.)  TYPE is a simple integer (/^\d+$/).  Supplying
"--dbitest[=TYPE]" as a first argument works even if no
other command-line processing is done, as Test::MockDBI
does its own command-line processing to check for this
first "--dbitest[=TYPE]" argument.  You will want to
add "--dbitest[=TYPE]" during a BEGIN block before the
"use Test::MockDBI", so that the mock DBI is initialized
as early as possible.

TYPE is optional, as a first argument of "--dbitest"
will set the DBI testing type to 1 (one).  DBI testing
is also disabled by "--dbitest=0" (although this
may not be generally useful).  The class method
Test::MockDBI::set_dbi_test_type() can also be used to
set or change the DBI testing type.

When DBI testing is disabled, DBI is used as you would
expect.  This makes using Test::MockDBI transparent to
your users.

The one exportable constant is:

=over 4

=item MOCKDBI_WILDCARD

MOCKDBI_WILDCARD is the wildcard DBI testing type
("--dbitest=TYPE"), used when the fetch*() functions should
always return the same value no matter what DBI testing
type has been set.

=back

External methods are:

=over 4

=item get_dbi_test_type()

Returns the numeric DBI test type. The type is 0 when not
testing the DBI interface.

=item set_dbi_test_type()

Sets the numeric DBI test type. The type is set to 0 if the
argument cannot be interpreted as a simple integer digit
string (/^\d+$/).

=item bad_method()

For the DBI method $method_name, when the DBI testing type
is $dbi_testing_type and the current SQL matches the regex
pattern in the string $matching_sql, make the function _fail
(usually by returning undef).

=item bad_param()

When the DBI testing type is $dbi_testing_type, make the
fetch*() functions fail if one of their corresponding
bind_param()s has parameter number $param_number with
the value $param_value.

=item set_retval_array()

When the DBI testing type is $dbi_testing_type and
the current SQL matches the pattern in the string
$matching_sql, fetch() and fetchrow_array() return the
contents of the array @retval.  If retval is actually a
CODEREF, the array returned from calling that subroutine
will be returned instead.

=item set_retval_scalar()

When the DBI testing type is $dbi_testing_type and the
current SQL matches the pattern in the string $matching_sql,
fetchall_arrayref(), fetchrow_arrayref(), fetchall_hashref(),
fetchrow_hashref(), and fetchrow() return the scalar value
$retval . If retval is actually a CODEREF, the scalar
returned from calling that subroutine will be returned
instead .

=item set_rows()

When the DBI testing type is $dbi_testing_type and
the current SQL matches the pattern in the string
$matching_sql, rows() returns the scalar value $rows.
If retval is actually a CODEREF, the scalar returned from
calling that subroutine will be returned instead.

=item set_errstr()

Allows I<errstr> to be set and unset at runtime.

=item get_instance()

Returns the Test::MockDBI instance.  This is a singleton.
Will print debug messages to stdout if given a defined argument.

=back

=head1 NOTES

A good source of Test::MockDBI examples is how the t/*.t
test programs works.

bad_method() forces developers to use a different DBI
testing type ("--dbitest=TYPE") for each different SQL
pattern for a DBI method.  This can be construed as
a feature.  (The workaround to this feature is to use
MOCKDBI_WILDCARD.)

DBI fetch() and fetchrow_array() will return the undef
value if the specified return value is a 1-element array
with undef as the only element.  I don't think this should
prove a major obstacle in testing.  It was coded this way
due to how Perl currently handles a return value of undef
when an array is expected, which is a one-element array
with undef as the only element.

MOCKDBI_WILDCARD is only supported for the fetch*()
return value setting methods, set_retval_scalar() and
set_retval_array().  It probably does not make sense for
the other external methods, as they are for creating DBI
failures (and how often do you want your code to fail for
all DBI testing types?)

If for some strange reason you should be installing
Test::MockDBI into a system with DBI but without any
DBD drivers (apart from DBD drivers bundled with DBI),
you can use:
    perl samples/DBD-setup.pl
    cp samples/DBI.cfg .
to create a sample DBM database (zipcodes.*) for testing
Test::MockDBI (DBD::DBM ships with DBI).

DBI fetchrow() is supported, although it is so old it
is no longer documented in the mainline DBI docs.

=head1 SEE ALSO

DBI, Test::MockObject::Extends, Test::Simple, Test::More,
perl(1)

DBD::Mock (another approach to testing DBI applications)

DBI trace() (still another approach to testing DBI
applications)

IO::String (for capturing standard output)

=head1 CAVEAT

=head2 fetch*_hashref does not allow modification of returned data
set.

This means you must copy-by-value if you wish to modify the data
before returning to the calling client.

=head1 AUTHOR

Mark Leighton Fisher,
E<lt>mark-fisher@fisherscreek.comE<gt>

Minor modifications (version 0.62 onwards) by
Andreas Faafeng
E<lt>aff@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004, Fisher's Creek Consulting, LLC.  Copyright
2004, DeepData, Inc.

=head1 LICENSE

This code is released under the same licenses as Perl
itself.

=cut
