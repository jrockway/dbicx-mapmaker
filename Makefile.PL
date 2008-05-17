use inc::Module::Install;

name 'DBICx-MapMaker';
all_from 'lib/DBICx/MapMaker.pm';

requires 'Moose';
requires 'Moose::Util::TypeConstraints';
build_requires 'DBICx::TestDatabase';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
