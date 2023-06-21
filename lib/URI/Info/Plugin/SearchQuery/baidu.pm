package URI::Info::Plugin::SearchQuery::baidu;

use 5.010001;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

use parent 'URI::Info::PluginBase';

sub meta {
    return {
        summary => 'Extract search query from baidu URL',
        conf => {
        },

        host => [
            'baidu.com',
            'www.baidu.com',

            'image.baidu.com',
            'tieba.baidu.com',
            'wenku.baidu.com',
            'zhidao.baidu.com',
        ],

        examples => [
        ],
    };
}

sub get_info {
    my ($self, $stash) = @_;
    my $url = $stash->{url};
    my $res = $stash->{res};

    my $host = $url->host;
    my $fpath = $url->full_path;

    if ($host eq 'b2b.baidu.com' && $fpath =~ m!\A/s\?!) {
        $res->{is_search} = 1;
        $res->{search_source} = 'baidu';
        $res->{search_type} = 'shopping';
        $res->{search_query} = $url->query_param('q');
    } elsif ($host eq 'image.baidu.com' && $fpath =~ m!\A/(search/index|i)\?!) {
        $res->{is_search} = 1;
        $res->{search_source} = 'baidu';
        $res->{search_type} = 'image';
        $res->{search_query} = $url->query_param('word');
    } elsif ($host eq 'map.baidu.com' && $fpath =~ m!\A/search/!) {
        $res->{is_search} = 1;
        $res->{search_source} = 'baidu';
        $res->{search_type} = 'map';
        ($res->{search_query}) = $url->path =~ m!\A/search/([^/]+)/!;
    } elsif ($host eq 'tieba.baidu.com' && $fpath =~ m!\A/f\?!) {
        $res->{is_search} = 1;
        $res->{search_source} = 'baidu';
        $res->{search_type} = 'forum';
        $res->{search_query} = $url->query_param('kw');
    } elsif ($host eq 'wenku.baidu.com' && $fpath =~ m!\A/search\?!) {
        $res->{is_search} = 1;
        $res->{search_source} = 'baidu';
        $res->{search_type} = 'books';
        $res->{search_query} = $url->query_param('word');
    } elsif ($host eq 'zhidao.baidu.com' && $fpath =~ m!\A/q\?!) {
        $res->{is_search} = 1;
        $res->{search_source} = 'baidu';
        $res->{search_type} = 'wiki';
        $res->{search_query} = $url->query_param('word');
    } elsif ($fpath =~ m!\A/sf/vsearch\?!) {
        $res->{is_search} = 1;
        $res->{search_source} = 'baidu';
        $res->{search_type} = 'video';
        $res->{search_query} = $url->query_param('word');
    } elsif ($fpath =~ m!\A/s\?!) {
        $res->{is_search} = 1;
        $res->{search_source} = 'baidu';
        $res->{search_type} =
            $url->query_param('tn') eq 'news' ? 'news' :
            'web';
        $res->{search_query} =
            $url->query_param('wd') //
            $url->query_param('word');
    }
    [200]; # 200=OK, 201=OK & skip the rest of the plugins, 500=error
}

1;
# ABSTRACT:

=for Pod::Coverage .+
