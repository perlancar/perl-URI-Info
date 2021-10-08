package URI::Info::PluginBase;

use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

1;
# ABSTRACT: Base class for URI::Info::Plugin::*
