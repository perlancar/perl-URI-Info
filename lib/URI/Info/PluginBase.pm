package URI::Info::PluginBase;

# AUTHORITY
# DATE
# DIST
# VERSION

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

1;
# ABSTRACT: Base class for URI::Info::Plugin::*
