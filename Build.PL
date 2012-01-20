use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name          => 'Email::ExactTarget',
	license              => 'artistic',
	dist_author          => q|Guillaume Aubert <aubertg@cpan.org>|,
	dist_version_from    => 'lib/Email/ExactTarget.pm',
	build_requires       =>
	{
		'Carp'           => 0,
		'Data::Dumper'   => 0,
		'HTML::Entities' => 0,
		'HTTP::Request'  => 0,
		'LWP::UserAgent' => 0,
		'Params::Util'   => 0,
		'SOAP::Lite'     => 0.71,
		'Test::Deep'     => 0,
		'Test::More'     => 0.94,
		'Text::Unaccent' => 0,
		'Try::Tiny'      => 0,
		'URI::Escape'    => 0,
	},
	requires             =>
	{
		'perl' => 5.006,
	},
	add_to_cleanup       => [ 'Email-ExactTarget-*' ],
	create_makefile_pl   => 'traditional',
	recursive_test_files => 1,
);

$builder->create_build_script();
