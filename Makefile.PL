# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'autobox-Closure-Attributes';
all_from       'lib/autobox/Closure/Attributes.pm';

requires       'parent';
requires       'autobox';
requires       'PadWalker';

build_requires 'Test::More';
build_requires 'Test::Exception';

auto_install;
WriteAll;

