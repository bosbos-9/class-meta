#!/usr/bin/perl -w

# $Id: custom_type_maker.t,v 1.7 2004/01/08 00:19:48 david Exp $

##############################################################################
# Set up the tests.
##############################################################################

package Class::Meta::Testing;

use strict;
use Test::More tests => 64;

BEGIN {
    use_ok('Class::Meta');
    use_ok( 'Class::Meta::Type' );
    our @ISA = qw(Class::Meta::Attribute);
}

my $attr = 'foo';
my $i = 0;
my ($set, $get, $acc, $err, $type);
my $obj = bless {};

##############################################################################
# Try creating a type with the bare minimum number of arguments.
ok( $type = Class::Meta::Type->add( name => 'Homer Object',
                                    key  => 'homer',
                                ),
    "Create Homer data type" );

is( $type, Class::Meta::Type->new('Homer'), 'Check lc conversion on key' );
is( $type->key, 'homer', "Check homer key" );
is( $type->name, 'Homer Object', "Check homer name" );
ok( ! defined $type->check, "Check homer checker" );

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $type->build(__PACKAGE__, $attr . ++$i, Class::Meta::GETSET),
    "Make simple homer set" );
ok( $acc = UNIVERSAL::can(__PACKAGE__, $attr . $i),
    "homer accessor exists");

# Test it.
my $homer = bless {}, 'Homer';
ok( $obj->$acc($homer), "Set homer value" );
is( $obj->$acc, $homer, "Check homer value" );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( $set = $type->make_attr_set($attr . $i), "Check homer attr_set" );
ok( $get = $type->make_attr_get($attr . $i), "Check homer attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), $homer, "Check homer getter" );
$homer = bless {}, 'Homer';
ok( $set->($obj, $homer), "Check homer setter" );
is( $get->($obj), $homer, "Check homer getter again" );

##############################################################################
# Try creating a type with an object type validation check.
ok( $type = Class::Meta::Type->add
  ( name  => 'Marge Object',
    key   => 'marge',
    check => 'Marge',
  ), "Create Marge data type" );

is( $type, Class::Meta::Type->new('Marge'),
    'Check lc conversion on key' );
is( $type->key, 'marge', "Check marge key" );
is( $type->name, 'Marge Object', "Check marge name" );
foreach my $chk (@{ $type->check }) {
    is( ref $chk, 'CODE', 'Check marge code');
}

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $type->build(__PACKAGE__, $attr . ++$i, Class::Meta::GETSET),
    "Make simple marge set" );
ok( $acc = UNIVERSAL::can(__PACKAGE__, $attr . $i),
    "marge accessor exists");

# Test it.
my $marge = bless {}, 'Marge';
ok( $obj->$acc($marge), "Set marge value" );
is( $obj->$acc, $marge, "Check marge value" );

# Make it fail the checks.
eval { $obj->$acc('foo') };
ok( $err = $@, "Got invalid marge error" );
like( $err, qr/^Value .* is not a valid Marge/,
      'correct marge exception' );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( $set = $type->make_attr_set($attr . $i), "Check marge attr_set" );
ok( $get = $type->make_attr_get($attr . $i), "Check marge attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), $marge, "Check marge getter" );
$marge = bless {}, 'Marge';
ok( $set->($obj, $marge), "Check marge setter" );
is( $get->($obj), $marge, "Check marge getter again" );

##############################################################################
# Try the same thing with undefs.
ok( $type = Class::Meta::Type->add( name    => 'Bart Object',
                                    key     => 'bart',
                                    check   => undef,
                                    builder => undef,
                                ),
    "Create Bart data type" );

is( $type, Class::Meta::Type->new('Bart'), 'Check lc conversion on key' );
is( $type->key, 'bart', "Check bart key" );
is( $type->name, 'Bart Object', "Check bart name" );
ok( ! defined $type->check, "Check bart checker" );

# Check to make sure that the accessor is created properly. Start with a
# simple set_ method.
ok( $type->build(__PACKAGE__, $attr . ++$i, Class::Meta::GETSET),
    "Make simple bart set" );
ok( $acc = UNIVERSAL::can(__PACKAGE__, $attr . $i),
    "bart accessor exists");

# Test it.
my $bart = bless {}, 'Bart';
ok( $obj->$acc($bart), "Set bart value" );
is( $obj->$acc, $bart, "Check bart value" );

# Check to make sure that the Attribute class accessor coderefs are getting
# created.
ok( $set = $type->make_attr_set($attr . $i), "Check bart attr_set" );
ok( $get = $type->make_attr_get($attr . $i), "Check bart attr_get" );

# Make sure they get and set values correctly.
is( $get->($obj), $bart, "Check bart getter" );
$bart = bless {}, 'Bart';
ok( $set->($obj, $bart), "Check bart setter" );
is( $get->($obj), $bart, "Check bart getter again" );

##############################################################################
# Now try one with the checker doing an isa() call.
ok( $type = Class::Meta::Type->add(
    name  => 'FooBar Object',
    key   => 'foobar',
    check => 'FooBar'
), "Create FooBar data type" );

is( ref $type->check, 'ARRAY', "Check foobar check" );
foreach my $check (@{ $type->check }) {
    is( ref $check, 'CODE', 'Check foobar code');
}

##############################################################################
# Now create our own checker.
ok( $type = Class::Meta::Type->add(
    name  => 'BarGoo Object',
    key   => 'bargoo',
    check => sub { 'bargoo' }
), "Create BarGoo data type" );

is( ref $type->check, 'ARRAY', "Check bargoo check" );
foreach my $check (@{ $type->check }) {
    is( ref $check, 'CODE', 'Check bargoo code');
}

##############################################################################
# And then try an array of checkers.
ok( $type = Class::Meta::Type->add(
    name  => 'Doh Object',
    key   => 'doh',
    check => [sub { 'doh' }, sub { 'doh!' } ]
), "Create Doh data type" );

is( ref $type->check, 'ARRAY', "Check doh check" );
foreach my $check (@{ $type->check }) {
    is( ref $check, 'CODE', 'Check doh code');
}

##############################################################################
# And finally, pass in a bogus value for the check parameter.
eval {
    $type = Class::Meta::Type->add(
        name  => 'Bogus',
        key   => 'bogus',
        check => { so => 'bogus' }
    )
};
ok( $err = $@, "Error for bogus check");
like( $err, qr/Paremter 'check' in call to add\(\) must be a code/,
      "Proper error for bogus check");

##############################################################################
# Okay, now try to trigger errors by not passing in required paramters.
eval { $type = Class::Meta::Type->add(name => 'foo') };
ok($err = $@, "Error for missing key");
like( $err, qr/Parameter 'key' is required/, "Proper error for missing key");

eval { $type = Class::Meta::Type->add(key => 'foo') };
ok($err = $@, "Error for missing name");
like( $err, qr/Parameter 'name' is required/,
      "Proper error for missing name");

##############################################################################
# Now try to create one that exists already.
eval { $type = Class::Meta::Type->add(name => 'bart', key => 'bart') };
ok($err = $@, "Error for duplicate key");
like( $err, qr/Type 'bart' already defined/,
      "Proper error for duplicate key");

##############################################################################
# And finally, let's try some custom accessor code refs.
