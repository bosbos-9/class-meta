package Class::Meta;

=head1 NAME

Class::Meta - Class Automation and Introspection

=head1 SYNOPSIS

  use Class::Meta;


=head1 DESCRIPTION



=cut

##############################################################################
# Dependencies                                                               #
##############################################################################
use strict;
use Carp;
use Class::Meta::Class;
use Class::Meta::Property;
use Class::Meta::Method;

##############################################################################
# Constants                                                                  #
##############################################################################

# Visibility. These determine who can get metadata objects back from method
# calls.
use constant PRIVATE   => 0x00;
use constant PROTECTED => 0x01;
use constant PUBLIC    => 0x02;

# Authorization. These determine what kind of accessors (get, set, both, or
# none) are available for a given property or method.
use constant NONE      => 0x00;
use constant READ      => 0x01;
use constant WRITE     => 0x02;
use constant RDWR      => READ | WRITE;

# Method generation. These tell Class::Meta which accessors to create. Use
# NONE above for NONE. These will use the values in the auth argument by
# default. They're separate because sometimes an accessor needs to be build
# by hand, rather than custom-generated by Class::Meta, and the
# authorization needs to reflect that.
use constant GET       => 0x01;
use constant SET       => 0x02;
use constant GETSET    => GET | SET;

# Metadata types. Used internally for tracking the different types of
# Class::Meta objects.
use constant PROP      => 'prop';
use constant METH      => 'meth';
use constant CONST     => 'const';

##############################################################################
# Package Globals                                                            #
##############################################################################
use vars qw($VERSION);
$VERSION = "0.01";

##############################################################################
# Function and Closure Prototypes                                            #
##############################################################################
my $add_memb;

##############################################################################
# Constructors                                                               #
##############################################################################
{
    my %classes;

    sub new {
	my ($pkg, $key, $class) = @_;
	# Class defaults to caller. Key defaults to class.
	$class ||= caller;
	$key ||= $class;

	# Make sure we haven't been here before.
	croak "Class '$class' already created" if exists $classes{$class};

	# Set up the definition hash.
	my $def = { key => $key,
		    pkg => $class };

	# Record the class' inheritance.
	my @isa;
	foreach my $is ($class, eval '@' . $class . "::ISA") {
	    $def->{isa}{$is} = 1;
	    push @isa, $is;
	}
	$def->{isa_ord} = \@isa;

	# Instantiate a Class object.
	$def->{class} = Class::Meta::Class->new({ def => $classes{$class} });

	# Cache the definition.
	$classes{$class} = $def;

	# Return!
	return bless { pkg => $class }, ref $pkg || $pkg;
    }


##############################################################################
# Instance Methods                                                           #
##############################################################################
    sub my_class { $classes{ $_[0]->{pkg} }->{class} }
    sub set_name { $classes{ $_[0]->{pkg} }->{class}{name} = $_[1] }
    sub set_desc { $classes{ $_[0]->{pkg} }->{class}{desc} = $_[1] }

    sub add_prop {
	my ($self, %spec) = @_;
	# NOTE: Add spec testing using Params::Validate;
	return $add_memb->(PROP, $classes{ $self->{pkg} }, \%spec);
    }

    sub add_meth {
	my ($self, %spec) = @_;
	# NOTE: Add spec testing using Params::Validate;
	return $add_memb->(METH, $classes{ $self->{pkg} }, \%spec);
    }

    sub add_const {
	my ($self, %spec) = @_;
	# NOTE: Add spec testing using Params::Validate;
	return $add_memb->(CONST, $classes{ $self->{pkg} }, \%spec);
    }

    sub build {

    }
}

##############################################################################
# Private closures                                                           #
##############################################################################

{
    my %types = ( &PROP  => { label => 'Property',
			      class => 'Class::Meta::Property' },
		  &METH  => { label => 'Method',
			      class => 'Class::Meta::Method' },
		  &CONST => { label => 'Constructor',
			      class => 'Class::Meta::Constructor' }
		);

    $add_memb = sub {
	my ($type, $def, $spec) = @_;
	# Check to see if this member has been created already.
	Carp::croak("$types{$type}->{label} '$spec->{name}' already exists in "
		    . "class '$def->{class}'")
	  if exists $def->{$type . 's'}{$spec->{name}};

	if ($type eq METH) {
	    # Methods musn't conflict with constructors, either.
	    Carp::croak("Construtor '$spec->{name}' already exists in class "
			. "'$def->{class}'")
	      if exists $def->{consts}{$spec->{name}};
	} elsif ($type eq CONST) {
	    # Constructors musn't conflict with methods, either.
	    Carp::croak("Method '$spec->{name}' already exists in class "
			. "'$def->{class}'")
	      if exists $def->{meths}{$spec->{name}};
	}

	# Create the member object.
	$spec->{class} = $def->{class};
	my $memb = $def->{$type. 's'}{$spec->{name}} =
	  bless $spec, $types{$type}->{class};

	# Save the object if it needs accessors built. This will be cleaned
	# out when build() is called.
	push @{ $def->{build_ord} }, $memb;

	# Just return the object if it's private.
	return $memb if $spec->{vis} == PRIVATE;

	# Preserve the order in which the property is declared.
	# Assume at least protected here.
	push @{ $def->{'prot_' . $type . '_ord'} }, $spec->{name};
	push @{ $def->{prot_ord} }, [$type, $spec->{name}];
	if ($spec->{vis} == PUBLIC) {
	    # Save the position of the property from the public perspective.
	    push @{ $def->{$type . '_ord'} }, $spec->{name};
	    push @{ $def->{ord} }, [$type, $spec->{name}];
	}

	# Return the new property object.
	return $memb;
    };
}

1;
__END__

=head1 TO DO

=over 4

=item *

Make it possible to subclass all of the member classes, as well as
Class::Meta::Class, of course.

=back

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Class::Contract|Class::Contract>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
