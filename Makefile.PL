use inc::Module::Install;

name 'Hg-Lib';
license 'perl';
all_from 'lib/Hg/Lib.pm';

author_tests 'xt';

repository 'https://bitbucket.org/djerius/hg-lib';

tests_recursive;

requires 'Moo';
requires 'MooX::Attributes::Shadow';
requires 'MooX::Types::MooseLike';
requires 'Try::Tiny';

test_requires 'Test::More';
test_requires 'Moo::Role';
test_requires 'Probe::Perl';
test_requires 'Test::Exception';

readme_from;

WriteAll;
