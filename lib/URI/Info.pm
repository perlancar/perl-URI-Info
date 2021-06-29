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
    $self->_init;
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
            if (ref $prefix) {
                die "[URI::Info] exclude_plugins entry cannot be array/reference: $prefix";
            }
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

    for my $entry (@{ $self->{include_plugins} }) {
        my ($prefix, $args);
        if (ref $entry eq 'ARRAY') {
            $prefix = $entry->[0];
            $args = $entry->[1];
        } else {
            $prefix = $entry;
            $args = {};
        }
        my @plugins;
        if ($prefix eq '' || $prefix =~ /::\z/ ||
                String::Wildcard::Bash::contains_wildcard($prefix)) {
            my $mods = Module::List::Wildcard::list_modules(
                "${p}$prefix", {list_modules=>1, wildcard=>1});
            for (keys %mods) {
                my $mod = $_;
                s/\A\Q$p\E//;
                if ($exclude_plugins{$_}) {
                    log_debug "[URI::Info] plugin '$_' is excluded (matches $prefix)";
                    next;
                }
                (my $mod_pm = "$mod.pm") =~ s!::!/!g;
                require $mod_pm;
                $self->_activate_plugin($mod, $args);
            }
        } else {
            my ($site, $event, $prio);
            $prefix =~ s/\@(\d+)?\z// and $prio = $1 if defined $1;
            $prefix =~ s/\@(\w+)\z// and $event = $1 if defined $1;
            $prefix =~ s/\@([^@]+)?\z// and $site = $1 if defined $1;
            my $mod = "${p}$prefix";
            my $path = Module::Path::More::module_path(module=>$mod);
            if ($path) {
                if ($exclude_plugins{$prefix}) {
                    log_debug "[URI::Info] plugin '$_' is excluded";
                    next;
                }
                (my $mod_pm = "$mod.pm") =~ s!::!/!g;
                require $mod_pm;
                $self->_activate_plugin($mod, $args, $site, $event, $prio);
            } else {
                die "[URI::Info] plugin '$_' cannot be found";
            }
        }
    }
}

sub _activate_plugin {
    my ($self, $mod, $args, $wanted_site, $wanted_event, $prio) = @_;
    $prio //= 50;

    # instantiate plugin object
    my $obj = $mod->new;
}

sub _run_event {
    my ($self, %args) = @_;

    my $name = $args{name};
    {
        local $args{code} = '...';
        local $args{r} = '...';
        log_trace "[URI::Info] -> run_event(%s)", \%args;
    }
    defined $name or die "Please supply 'name'";
    $Handlers{$name} ||= [];

    my $before_name = "before_$name";
    $Handlers{$before_name} ||= [];

    my $after_name = "after_$name";
    $Handlers{$after_name} ||= [];

    my $req_handler                          = $args{req_handler};                          $req_handler                          = 0 unless defined $req_handler;
    my $run_all_handlers                     = $args{run_all_handlers};                     $run_all_handlers                     = 1 unless defined $run_all_handlers;
    my $allow_before_handler_to_cancel_event = $args{allow_before_handler_to_cancel_event}; $allow_before_handler_to_cancel_event = 1 unless defined $allow_before_handler_to_cancel_event;
    my $allow_before_handler_to_skip_rest    = $args{allow_before_handler_to_skip_rest};    $allow_before_handler_to_skip_rest    = 1 unless defined $allow_before_handler_to_skip_rest;
    my $allow_handler_to_skip_rest           = $args{allow_handler_to_skip_rest};           $allow_handler_to_skip_rest           = 1 unless defined $allow_handler_to_skip_rest;
    my $allow_handler_to_repeat_event        = $args{allow_handler_to_repeat_event};        $allow_handler_to_repeat_event        = 1 unless defined $allow_handler_to_repeat_event;
    my $allow_after_handler_to_repeat_event  = $args{allow_after_handler_to_repeat_event};  $allow_after_handler_to_repeat_event  = 1 unless defined $allow_after_handler_to_repeat_event;
    my $allow_after_handler_to_skip_rest     = $args{allow_after_handler_to_skip_rest};     $allow_after_handler_to_skip_rest     = 1 unless defined $allow_after_handler_to_skip_rest;
    my $stop_after_first_handler_failure     = $args{stop_after_first_handler_failure};     $stop_after_first_handler_failure     = 1 unless defined $stop_after_first_handler_failure;

    my ($res, $is_success);

  RUN_BEFORE_EVENT_HANDLERS:
    {
        last if $name =~ /\A(after|before)_/;
        local $r->{event} = $before_name;
        my $i = 0;
        for my $rec (@{ $Handlers{$before_name} }) {
            $i++;
            my ($label, $prio, $handler) = @$rec;
            log_trace "[URI::Info] [event %s] [%d/%d] -> handler %s ...",
                $before_name, $i, scalar(@{ $Handlers{$before_name} }), $label;
            $res = $handler->($r);
            $is_success = $res->[0] =~ /\A[123]/;
            log_trace "[URI::Info] [event %s] [%d/%d] <- handler %s: %s (%s)",
                $before_name, $i, scalar(@{ $Handlers{$before_name} }), $label,
                $res, $is_success ? "success" : "fail";
            if ($res->[0] == 601) {
                if ($allow_before_handler_to_cancel_event) {
                    log_trace "[pericmd] Cancelling event $name (status 601)";
                    goto RETURN;
                } else {
                    die "$before_name handler returns 601 when allow_before_handler_to_cancel_event is set to false";
                }
            }
            if ($res->[0] == 201) {
                if ($allow_before_handler_to_skip_rest) {
                    log_trace "[pericmd] Skipping the rest of the $before_name handlers (status 201)";
                    last RUN_BEFORE_EVENT_HANDLERS;
                } else {
                    log_trace "[pericmd] $before_name handler returns 201, but we ignore it because allow_before_handler_to_skip_rest is set to false";
                }
            }
        }
    }

  RUN_EVENT_HANDLERS:
    {
        local $r->{event} = $name;
        my $i = 0;
        $res = [304, "There is no handler for event $name"];
        $is_success = 1;
        if ($req_handler) {
            die "There is no handler for event $name"
                unless @{ $Handlers{$name} };
        }

        for my $rec (@{ $Handlers{$name} }) {
            $i++;
            my ($label, $prio, $handler) = @$rec;
            log_trace "[pericmd] [event %s] [%d/%d] -> handler %s ...",
                $name, $i, scalar(@{ $Handlers{$name} }), $label;
            $res = $handler->($r);
            $is_success = $res->[0] =~ /\A[123]/;
            log_trace "[pericmd] [event %s] [%d/%d] <- handler %s: %s (%s)",
                $name, $i, scalar(@{ $Handlers{$name} }), $label,
                $res, $is_success ? "success" : "fail";
            last RUN_EVENT_HANDLERS if $is_success && !$run_all_handlers;
            if ($res->[0] == 601) {
                die "$name handler is not allowed to return 601";
            }
            if ($res->[0] == 602) {
                if ($allow_handler_to_repeat_event) {
                    log_trace "[pericmd] Repeating event $name (handler returns 602)";
                    goto RUN_EVENT_HANDLERS;
                } else {
                    die "$name handler returns 602 when allow_handler_to_repeat_event is set to false";
                }
            }
            if ($res->[0] == 201) {
                if ($allow_handler_to_skip_rest) {
                    log_trace "[pericmd] Skipping the rest of the $name handlers (status 201)";
                    last RUN_EVENT_HANDLERS;
                } else {
                    log_trace "[pericmd] $name handler returns 201, but we ignore it because allow_handler_to_skip_rest is set to false";
                }
            }
            last RUN_EVENT_HANDLERS if !$is_success && $stop_after_first_handler_failure;
        }
    }

    if ($is_success && $args{on_success}) {
        log_trace "[pericmd] Running on_success ...";
        $args{on_success}->($r);
    } elsif (!$is_success && $args{on_failure}) {
        log_trace "[pericmd] Running on_failure ...";
        $args{on_failure}->($r);
    }

  RUN_AFTER_EVENT_HANDLERS:
    {
        last if $name =~ /\A(after|before)_/;
        local $r->{event} = $after_name;
        my $i = 0;
        for my $rec (@{ $Handlers{$after_name} }) {
            $i++;
            my ($label, $prio, $handler) = @$rec;
            log_trace "[pericmd] [event %s] [%d/%d] -> handler %s ...",
                $after_name, $i, scalar(@{ $Handlers{$after_name} }), $label;
            $res = $handler->($r);
            $is_success = $res->[0] =~ /\A[123]/;
            log_trace "[pericmd] [event %s] [%d/%d] <- handler %s: %s (%s)",
                $after_name, $i, scalar(@{ $Handlers{$after_name} }), $label,
                $res, $is_success ? "success" : "fail";
            if ($res->[0] == 602) {
                if ($allow_after_handler_to_repeat_event) {
                    log_trace "[pericmd] Repeating event $name (status 602)";
                    goto RUN_EVENT_HANDLERS;
                } else {
                    die "$after_name handler returns 602 when allow_after_handler_to_repeat_event it set to false";
                }
            }
            if ($res->[0] == 201) {
                if ($allow_after_handler_to_skip_rest) {
                    log_trace "[pericmd] Skipping the rest of the $after_name handlers (status 201)";
                    last RUN_AFTER_EVENT_HANDLERS;
                } else {
                    log_trace "[pericmd] $after_name handler returns 201, but we ignore it because allow_after_handler_to_skip_rest is set to false";
                }
            }
        }
    }

  RETURN:
    log_trace "[pericmd] <- run_event(name=%s)", $name;
    undef;
}

my $handler_seq = 0;
sub __plugin_add_handler {
    my ($event, $label, $prio, $handler) = @_;

    # XXX check for known events?
    $Handlers{$event} ||= [];

    # keep sorted
    splice @{ $Handlers{$event} }, 0, scalar(@{ $Handlers{$event} }),
        (sort { $a->[1] <=> $b->[1] || $a->[3] <=> $b->[3] } @{ $Handlers{$event} },
         [$label, $prio, $handler, $handler_seq++]);
}

sub info {
    my $self = shift;
    my $url = shift;

    for my $plugin (@{ $self->{loaded_plugin} }) {
    }
}

sub uri_info {
    state $obj = __PACKAGE__->new;
    $obj->info($_);
}

1;
# ABSTRACT: Extract various information from a URI (URL)

=head1 SYNOPSIS

 use URI::Info;

 my $info = URI::Info->new(
     # include_plugins => ['Search::*'],  # only use these plugins. by default, all plugins will be loaded
     # exclude_plugins => [...],          # don't use certain plugins
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


=head1 METHODS

=head2 new

Usage:

 my $obj = URI::Info->new(%args);

Constructor. Known arguments (C<*> marks required arguments):

=over

=item * include_plugins

Array of plugins (names or wildcard patterns or names+arguments) to include.
Plugin name is module name under C<URI::Info::Plugin::> without the prefix, e.g.
C<SearchQuery::tokopedia> with optional site name
(C<SearchQuery::tokopedia@foo.com>), event name (e.g.
C<Debug::DumpStash@@before_get_info>), and priority (e.g.
C<Debug::DumpStash@@before_get_info@99>). Wildcard pattern is a pattern
containing wildcard characters, e.g C<SearchQuery::toko*> or C<SearchQuery::**>
(see L<Module::List::Wildcard> for more details on the wildcard). You cannot
special optional site name, event name, or priority when using wildcard pattern.
name+argument is a 2-array arrayref where the first element is plugin name or
wildcard pattern, and the second element is hashref of arguments to instantiate
the plugin with, e.g. C<< ['SearchQuery::tokopedia', {foo=>1, bar=>2, ...}] >>.

If unspecified, will list all installed modules under C<URI::Info::Plugin::> and
include them all.

=item * exclude_plugins

Array of plugins (names or wildcard patterns) to exclude.

Takes precedence over C<include_plugins> argument.

Default is empty array.

=back


=head1 FUNCTIONS

=head2 uri_info

Usage:

 my $hashref = uri_info($uri);

Return a hash of extracted pieces of information from a C<$uri> string. Will
consult the plugins to do the hard work. All the installed plugins will be used.
To customize the set of plugins to use, use the OO interface.


=head1 ENVIRONMENT

Planned: URI::Info will read C<URI_INFO_PLUGINS> to include/exclude plugins,
with this syntax:

 -Plugin1ToExclude,+Plugin2ToInclude,arg1,val1,...,+Plugin3ToInclude@Site@EventName@Priority,...


=head1 SEE ALSO

L<URI::ParseSearchString>

=cut
