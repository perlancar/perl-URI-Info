package URI::Info;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

sub new {
    my ($class, %args) = @_;

    for (keys %args) {
        die "Unknown argument '$_', known arguments are include_plugins, exclude_plugins"
            unless /\A(include_plugins|exclude_plugins)\z/;
    }
    my $self = bless \%args, $class;

    $self->_load_plugins;
    $self;
}

my $p = "URI::Info::Plugin::";
sub _load_plugins {
    require Module::List::Wildcard;
    require Module::Path::More;
    require String::Wildcard::Bash;

    my $self = shift;

    my %exclude_plugins;
    if ($self->{exclude_plugins} && @{ $self->{exclude_plugins} }) {
        for my $prefix (@{ $self->{exclude_plugins} }) {
            if ($prefix eq '' || $prefix =~ /::\z/ ||
                    String::Wildcard::Bash::contains_wildcard($prefix)) {
                my $mods = Module::List::Wildcard::list_modules(
                    "${p}$prefix", {list_modules=>1, wildcard=>1});
                for (keys %mods) {
                    s/\A\Q$p\E//;
                    $exclude_plugins{$_}++;
                }
            } else {
                my $path = Module::Path::More::module_path(
                    module=>"${p}$prefix");
                if ($path) {
                    $exclude_plugins{$prefix}++;
                }
            }
        }
    }

    my %include_plugins;
    for my $prefix (@{ $self->{include_plugins} }) {
        if ($prefix eq '' || $prefix =~ /::\z/ ||
                String::Wildcard::Bash::contains_wildcard($prefix)) {
            my $mods = Module::List::Wildcard::list_modules(
                "${p}$prefix", {list_modules=>1, wildcard=>1});
            for (keys %mods) {
                s/\A\Q$p\E//;
                if ($exclude_plugins{$_}) {
                    log_debug "URI::Info plugin '$_' is excluded (matches $prefix)";
                    next;
                }
                $include_plugins{$_}++;
            }
        } else {
            my $path = Module::Path::More::module_path(
                module=>"${p}$prefix");
            if ($path) {
                if ($exclude_plugins{$prefix}) {
                    log_debug "URI::Info plugin '$_' is excluded";
                    next;
                }
                $include_plugins{$prefix}++;
            } else {
                die "URI::Info plugin '$_' cannot be found";
            }
        }
    }

    my @loaded_plugins;
    for my $plugin (sort keys %include_plugins) {
        log_trace "Loading URI::Info plugin '$plugin' ...";
        my $mod = "URI::Info::Plugin::$plugin";
        (my $modpm = "$mod.pm") =~ s!::!/!g;
        require $modpm;
    }

    $self->{loaded_plugins} = \@include_plugins;
}

1;
# ABSTRACT: Extract various information from a URI (URL)

=head1 SYNOPSIS

 use URI::Info;

 my $info = URI::Info->new(
     # -include_plugins => ['Search::*'],  # only use these plugins. by default, all plugins will be loaded
     # -exclude_plugins => [...],          # don't use certain plugins
 );

 my $res = $info->info("https://www.google.com/search?safe=off&oq=kathy+griffin");
 # => {
 #        host => "www.google.com",
 #        is_search=>1,
 #        search_engine=>"Google",
 #        search_string=>"kathy griffin",
 # }


=head1 DESCRIPTION

This module (and its plugins) will let you extract various information from a
piece of URI (URL) string.

Keywords: URI parser, URL parser, search string extractor


=head1 FUNCTIONS

=head2 uri_info

Usage:

 my $hashref = uri_info($uri);

Return a hash of extracted pieces of information from a C<$uri> string. Will
consult the plugins to do the hard work.


=head1 SEE ALSO

L<URI::ParseSearchString>

=cut
