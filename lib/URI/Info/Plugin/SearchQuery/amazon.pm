package URI::Info::Plugin::SearchQuery::amazon;

use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

use parent 'URI::Info::PluginBase';

sub meta {
    return {
        summary => 'Extract search query from Amazon URL',
        conf => {
        },

        host => [
            'amazon.ae',
            'amazon.ca',
            'amazon.cn',
            'amazon.co.jp',
            'amazon.com',
            'amazon.com.au',
            'amazon.com.be',
            'amazon.com.br',
            'amazon.com.mx',
            'amazon.com.tr',
            'amazon.co.uk',
            'amazon.de',
            'amazon.eg',
            'amazon.es',
            'amazon.fr',
            'amazon.in',
            'amazon.it',
            'amazon.nl',
            'amazon.sa',
            'amazon.se',
            'amazon.sg',
        ],
    };
}

sub get_info {
    my ($self, $stash) = @_;
    my $url = $stash->{url};
    my $res = $stash->{res};

    if ($url->full_path =~ m!\A/s\?)!) {
        $res->{is_search} = 1;
        $res->{search_source} = 'amazon';
        $res->{search_query} =
            $url->query_param('k') //;
            $url->query_param('field-keywords') //;
    }
    [200]; # 200=OK, 201=OK & skip the rest of the plugins, 500=error
}

1;
# ABSTRACT:

=for Pod::Coverage .+
