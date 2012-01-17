#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;

use Email::ExactTarget;


eval 'use ExactTargetConfig';
$@
	? plan( skip_all => 'Local connection information for ExactTarget required to run tests.' )
	: plan( tests => 6 );


# Retrieve the local config.
my $config = ExactTargetConfig->new();

# Retrieve the list of addresses to use for testing.
my $test_list_subscriptions = {};
foreach my $line ( <DATA> )
{
	chomp( $line );
	next if !defined( $line ) || substr( $line, 0, 1 ) eq '#' || $line !~ /\w/;
	my ( $email, @list_id ) = split( /\t/, $line );
	
	# Replace placeholders.
	foreach my $list_id ( @list_id )
	{
		$list_id = $config->{'all_subscribers_list_id'} if $list_id eq '[default]';
		$list_id = $config->{'test_lists'}->[$1] if $list_id =~ /\[test(\d+)\]/;
	}
	
	$test_list_subscriptions->{ $email } = \@list_id;
}
isnt(
	scalar( keys %$test_list_subscriptions ),
	0,
	'Find test emails.'
);

# Create an object to communicate with Exact Target.
my $exact_target = Email::ExactTarget->new( %$config );
ok(
	defined( $exact_target ),
	'Create a new Email::ExactTarget object.',
) || diag( explain( $exact_target ) );

# Get a subscriber operations object.
my $subscriber_operations = $exact_target->subscriber_operations();
isa_ok(
	$subscriber_operations,
	'Email::ExactTarget::SubscriberOperations',
	'$subscriber_operations',
);

# Retrieve the subscriber objects.
my $subscribers;
eval
{
	$subscribers = $subscriber_operations->retrieve(
		'email' => [ keys %$test_list_subscriptions ],
	);
};
ok(
	!$@,
	'Retrieve subscribers.',
) || diag( "Error: $@" );

# Retrieve the list subscriptions for the subscribers.
eval
{
	$subscriber_operations->pull_list_subscriptions(
		$subscribers
	);
};
ok(
	!$@,
	'Retrieve list subscriptions.',
) || diag( "Error: $@" );

# Make it easier later to test individual results by accessing the objects.
# by email.
my $subscribers_by_email =
{
	map
		{ $_->get('Email Address') => $_ }
		@$subscribers
};

# Test that the list subscriptions are correct.
subtest(
	'List subscriptions are correctly set up.',
	sub
	{
		plan( tests => scalar( keys %$test_list_subscriptions ) * 2 );
		
		foreach my $email ( keys %$test_list_subscriptions )
		{
			my $subscriber = exists( $subscribers_by_email->{ $email } )
				? $subscribers_by_email->{ $email }
				: undef;
			
			ok(
				defined( $subscriber ),
				"Find the subscriber object for $email.",
			);
			
			my $live_list_subscriptions = $subscriber->get_lists_status( 'is_live' => 1 );
			my $expected =
			{
				map
					{ $_ => 'Active' }
					@{ $test_list_subscriptions->{ $email } || [] }
			};
			cmp_deeply(
				$live_list_subscriptions || [],
				$expected,
				"The subscriptions for $email are correct.",
			) || diag( 'Got ' . Dumper( $live_list_subscriptions ) . "\nExpected: " . Dumper( $expected ) );
		}
	}
);


__DATA__
# Note: The list IDs are tab separated, and the following placeholders are
# available:
#     - [default]: the ID of the "all subscribers" list.
#     - [test0], [test1], etc: the IDs of the lists defined in
#         $config->{'test_lists'}.
#
# Email	List IDs
john.q.public@example.com	[default]	[test0]
john.doe@example.com	[default]	[test1]
