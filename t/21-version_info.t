#!perl -T

use strict;
use warnings;

use Test::More;

use Email::ExactTarget;


eval 'use ExactTargetConfig';
$@
	? plan( skip_all => 'Local connection information for ExactTarget required to run tests.' )
	: plan( tests => 4 );

my $config = ExactTargetConfig->new();

# Create an object to communicate with Exact Target
my $exact_target = Email::ExactTarget->new( %$config );
ok(
	defined( $exact_target ),
	'Create a new Email::ExactTarget object.',
) || diag( explain( $exact_target ) );

my $response_data;
eval
{
	$response_data = $exact_target->version_info();
};
ok(
	!$@,
	'Retrieve version info.',
) || diag( explain( $@ ) );

ok(
	defined( $response_data ),
	'Response is not empty.',
) || diag( explain( $response_data ) );

my $version = $response_data->{'Version'};
ok(
	defined( $version ) && ( $version ne '' ),
	'The version is defined.',
) || diag( explain( $response_data ) );
diag( "ExactTarget's webservice reports version $version." );
