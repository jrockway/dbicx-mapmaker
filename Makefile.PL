use inc::Module::Install;

name 'DBICx-MapMaker';
all_from 'lib/DBICx/MapMaker.pm';

build_requires 'Test::More';
build_requires 'ok';

WriteAll();
