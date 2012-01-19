package Email::ExactTarget::Subscriber;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use URI::Escape;


=head1 NAME

Email::ExactTarget::Subscriber


=head1 VERSION

Version 1.2.0

=cut

our $VERSION = '1.2.0';


=head1 SYNOPSIS

	# Create a new subscriber object.
	my $subscriber = Email::ExactTarget::Subscriber->new();
	
	# Set attributes.
	$subscriber->set(
		{
			'First Name' => 'John',
			'Last Name'  => 'Doe',
		}
	);
	
	# Get attributes.
	my $first_name = $subscriber->get('First Name');
	
	# ExactTarget's subscriber ID, if applicable.
	my $subscriber_id = $subscriber->id();


=head1 METHODS

=head2 new()

Creates a new Subscriber object.

	my $subscriber = Email::ExactTarget::Subscriber->new();

=cut

sub new
{
	my ( $class, %args ) = @_;

	# Create the object.
	my $self = bless(
		{
			'attributes'        => {},
			'staged_attributes' => {},
			'lists'             => {},
			'staged_lists'      => {},
		},
		$class
	);

	return $self;
}


=head2 set()

Sets the attributes and values for the current subscriber object.

	$subscriber->set(
		{
			'Email Address' => $email,
			'First Name'    => $first_name,
		},
		'is_live' => $boolean, #default 0
	);

The I<is_live> parameter allows specifying whether the data in the hashref are
local only or if they are already synchronized with ExactTarget's database. By
default, changes are considered local only and you will explicitely have to
synchronize them using the functions of
Email::ExactTarget::SubscriberOperations.

=cut

sub set
{
	my ( $self, $attributes, %args ) = @_;
	my $is_live = delete( $args{'is_live'} ) || 0;
	
	my $storage_key = $is_live ? 'attributes' : 'staged_attributes';
	while ( my ( $name, $value ) = each( %$attributes ) )
	{
		$self->{ $storage_key }->{ $name } = $value;
	}
	
	return 1;
}


=head2 id()

Returns the Subscriber ID associated to the current Subscriber in Exact Target's
database.

	$subscriber->id( 123456789 );

	my $subscriber_id = $subscriber->id();

This will return undef if the object hasn't loaded the subscriber information
from the database, or if a new subscriber hasn't been committed to the database.

=cut

sub id
{
	my ( $self, $id ) = @_;
	
	if ( defined( $id ) )
	{
		confess 'Subscriber ID format is incorrect'
			unless $id =~ m/^\d+$/;
		
		confess 'The subscriber ID is already set on this object'
			if defined( $self->{'id'} );
		
		$self->{'id'} = $id;
	}
	
	return $self->{'id'};
}


=head2 get()

When passed an attribute name as a parameter, retrieves the corresponding value:

	my $email = $subscriber->get( 'Email Address' );

Note that this will only show the live (retrieved from ExactTarget) values. If
changes have been staged locally, this won't retrieve the new values until you
synchronize them using one of the methods in
Email::ExactTarget::SubscriberOperations.

#TODO: update documentation to reflect the is_live option.

=cut

sub get
{
	my ( $self, $attribute, %args ) = @_;
	my $is_live = delete( $args{'is_live'} );
	$is_live = 1 unless defined( $is_live );
	
	confess 'An attribute name is required to retrieve the corresponding value'
		if !defined( $attribute ) || ( $attribute eq '' );
	
	my $storage_key = $is_live ? 'attributes' : 'staged_attributes';
	
	carp "The attribute '$attribute' does not exist on the Subscriber object"
		unless exists( $self->{ $storage_key }->{ $attribute } );
	
	return $self->{ $storage_key }->{ $attribute };
}


=head2 get_attributes()

Retrieve a hashref containing all the attributes of the current object.

By default, it retrieves the live data (i.e., attributes synchronized with
ExactTarget). If you want to retrieve the staged data, you can set
I<is_live => 0> in the parameters.

	# Retrieve staged attributes (i.e., not synchronized yet with ExactTarget).
	my $attributes = $subscriber->get_attributes( 'is_live' => 0 );
	
	# Retrieve live attributes.
	my $attributes = $subscriber->get_attributes( 'is_live' => 1 );
	my $attributes = $subscriber->get_attributes();

=cut

sub get_attributes
{
	my ( $self, %args ) = @_;
	my $is_live = delete( $args{'is_live'} );
	$is_live = 1 unless defined( $is_live );
	
	my $storage_key = $is_live
		? 'attributes'
		: 'staged_attributes';
	
	# Make a copy of the attributes before returning them, in case the caller
	# needs to modify the hash.
	return { %{ $self->{ $storage_key } || {} } };
}


=head2 apply_staged_attributes()

Moves the staged attribute changes onto the current object, effectively
'applying' the changes.

	$subscriber->apply_staged_attributes(
		[
			'Email Address',
			'First Name',
		]
	) || confess Dumper( $subscriber->errors() );

=cut

sub apply_staged_attributes
{
	my ( $self, $fields ) = @_;
	
	confess 'The first parameter needs to be an arrayref of fields to apply'
		unless defined $fields && UNIVERSAL::isa( $fields, 'ARRAY' );
	
	my $errors_count = 0;
	foreach my $field ( @$fields )
	{
		eval
		{
			$self->set(
				{
					$field => $self->{'staged_attributes'}->{ $field },
				},
				'is_live' => 1,
			);
		};
		
		if ( !$@ )
		{
			delete( $self->{'staged_attributes'}->{ $field } );
		}
		else
		{
			$errors_count++;
			$self->add_error( "Failed to apply the staged values for the following attribute: $field." );
		}
	}
	
	return $errors_count > 0 ? 0 : 1;
}


=head2 set_lists_status()

Stores the list IDs and corresponding subscription status.

	$subscriber->set_lists_status(
		{
			'1234567' => 'Active',
			'1234568' => 'Unsubscribed',
		},
		'is_live' => $boolean, #default 0
	);

The I<is_live> parameter allows specifying whether the data in the hashref are
local only or if they are already synchronized with ExactTarget's database. By
default, changes are considered local only and you will explicitely have to
synchronize them using the functions of
Email::ExactTarget::SubscriberOperations.

'Active' and 'Unsubscribed' are the two valid statuses for list subscriptions.

=cut

sub set_lists_status
{
	my ( $self, $statuses, %args ) = @_;
	my $is_live = delete( $args{'is_live'} ) || 0;
	
	# Verify the new status for each list.
	while ( my ( $list_id, $status ) = each( %$statuses ) )
	{
		confess "The status for list ID >$list_id< must be defined"
			unless defined( $status );
		
		confess "The status >$status< for list ID >$list_id< is incorrect"
			unless $status =~ m/^(Active|Unsubscribed)$/;
	}
	
	# If all the status passed are valid, we can now proceed with updating the
	# subscriber object (we want all updates or none).
	my $storage_key = $is_live ? 'lists' : 'staged_lists';
	while ( my ( $list_id, $status ) = each( %$statuses ) )
	{
		$self->{ $storage_key }->{ $list_id } = $status;
	}
	
	return 1;
}


=head2 get_lists_status ()

Returns the subscription status for the lists on the current object.

By default, it retrieves the live data (i.e., list subscriptions synchronized
with ExactTarget). If you want to retrieve the staged data, you can set
I<is_live => 0> in the parameters.

This function takes one mandatory parameter, which indicates whether you want
the staged list information (lists subscribed to locally but not yet
synchronized with ExactTarget) or the live list information (lists subscribed to
in ExactTarget's database). The respective options are I<staged> for the staged
information, and I<live> for the live information.

	# Retrieve staged attributes (i.e., not synchronized yet with ExactTarget).
	my $lists_status = $self->get_lists_status( 'is_live' => 0 );
	
	# Retrieve live attributes.
	my $lists_status = $self->get_lists_status( 'is_live' => 1 );
	my $lists_status = $self->get_lists_status();

=cut

sub get_lists_status
{
	my ( $self, %args ) = @_;
	my $is_live = delete( $args{'is_live'} );
	$is_live = 1 unless defined( $is_live );
	
	my $storage_key = $is_live
		? 'lists'
		: 'staged_lists';
	
	return { %{ $self->{ $storage_key } || {} } };
}


=head2 apply_staged_lists_status()

Moves the staged list subscription changes onto the current object, effectively
'applying' the changes.

	$subscriber->apply_staged_lists_status(
		[
			'1234567'
			'1234568',
		]
	) || confess Dumper( $subscriber->errors() );

=cut

sub apply_staged_lists_status
{
	my ( $self, $lists_status ) = @_;
	
	confess 'The first parameter needs to be an hashref of list IDs and statuses to apply'
		unless defined( $lists_status ) && UNIVERSAL::isa( $lists_status, 'HASH' );
	
	my $errors_count = 0;
	while ( my ( $list_id, $status ) = each( %$lists_status ) )
	{
		eval
		{
			$self->set_lists_status(
				{
					$list_id => $status,
				},
				'is_live' => 1,
			);
		};
		
		if ( !$@ )
		{
			delete( $self->{'staged_lists'}->{ $list_id } );
		}
		else
		{
			$errors_count++;
			$self->add_error( "Failed to apply the staged list statuses for the following list ID: $list_id." );
		}
	}
	
	return $errors_count > 0 ? 0 : 1;
}


=head2 add_error()

Adds a new error message to the current object.

	$subscriber->add_error( 'Cannot update object.' ) || confess 'Failed to add error';

=cut

sub add_error
{
	my ( $self, $error ) = @_;
	
	if ( !defined( $error ) || ( $error eq '' ) )
	{
		carp 'No error text specified';
		return 0;
	}
	
	$self->{'errors'} ||= [];
	push( @{ $self->{'errors'} }, $error );
	return 1;
}


=head2 errors()

Returns the errors stored on the current object as an arrayref if there is any,
otherwise returns undef.

	# Retrieve the errors.
	my $errors = $subscriber->errors();
	if ( defined( $errors ) )
	{
		print Dumper( $errors );
	}

	# Retrieve and remove the errors.
	my $errors = $subscriber->errors( reset => 1 );
	if ( defined( $errors ) )
	{
		print Dumper( $errors );
	}

=cut

sub errors
{
	my ( $self, %args ) = @_;
	my $reset = delete( $args{'reset'} ) || 0;
	
	my $errors = $self->{'errors'};
	
	# If the options require it, removes the errors on the current object.
	$self->{'errors'} = []
		if $reset;
	
	return $errors;
}


=head1 AUTHOR

Guillaume Aubert, C<< <aubertg at cpan.org> >>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-email-exacttarget at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-ExactTarget>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Email::ExactTarget::Subscriber


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-ExactTarget>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-ExactTarget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-ExactTarget>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-ExactTarget/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to ThinkGeek (L<http://www.thinkgeek.com/>) and its corporate overlords
at Geeknet (L<http://www.geek.net/>), for footing the bill while I eat pizza
and write code for them!


=head1 COPYRIGHT & LICENSE

Copyright 2009-2012 Guillaume Aubert.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
