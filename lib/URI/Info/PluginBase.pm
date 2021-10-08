package URI::Info::PluginBase;

use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

sub new {
    my ($class, %args) = @_;

    # check allowed arguments
    my $meta = $class->meta;
    my $conf = $meta->{conf};
    for my $arg (keys %args) {
        die "[URI::Info] Unrecognized plugin $class argument '$arg', please use one of ".join("/", sort keys %$conf)
            unless exists $conf->{$arg};
    }

    bless \%args, $class;
}

1;
# ABSTRACT: Base class for URI::Info::Plugin::*

=for Pod::Coverage .+
