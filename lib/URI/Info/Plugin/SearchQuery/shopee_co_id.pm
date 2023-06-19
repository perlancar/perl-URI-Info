package URI::Info::Plugin::SearchQuery::shopee_co_id;

use strict;
use warnings;

use parent 'URI::Info::PluginBase';

# AUTHORITY
# DATE
# DIST
# VERSION

sub meta {
    return {
        summary => 'Extract search query from shopee.co.id URL',
        conf => {
        },
        host => 'shopee.co.id',
    };
}

sub get_info {
    my ($self, $stash) = @_;
    my $url = $stash->{url};
    my $res = $stash->{res};

    if ($url->full_path =~ m!\A/search!) {
        $res->{is_search} = 1;
        $res->{search_type} = 'product'; # ?
        $res->{search_query} = $url->query_param('keyword');
    }
    [200]; # 200=OK, 201=OK & skip the rest of the plugins, 500=error
}

1;
# ABSTRACT:

=for Pod::Coverage .+
