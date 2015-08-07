package ImageEditor::CMS;
use strict;

sub _mode_replace_asset {
    my $app = MT->instance();
    unless ( $app->can_do( 'save_asset' ) ) {
        return $app->errtrans( 'Permission denied.' );
    }
    my $plugin = MT->component( 'ImageEditor' );
    my $blog_id = $app->blog->id;
    my $new_url = $app->param( 'new_url' ) or return $app->errtrans( 'Invalid request.' );
    my $asset_id = $app->param( 'id' );
    my $asset = MT->model( 'asset' )->load( { id => $asset_id } );
    unless ( $asset ) {
        return $app->errtrans( 'Invalid request.' );
    }
    unless ( $asset->file_ext =~ /^(?:jpg|png|gif)$/ ) {
        return $app->errtrans( 'Invalid request.' );
    }
    my $ua = $app->new_ua;
    $ua->max_size( undef );
    my $res = $ua->get( $new_url );
    unless ( $res->is_success ) {
        return $app->error( sprintf( 'GETTING NEW IMAGE ERROR: %s', $res->status_line ) );
    }
    unless ( $res->header( 'content-length' ) == length $res->content ) {
       return $app->error( $plugin->translate( 'An error occurred during downloading image.' ) );
    }
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    $fmgr->put_data( $res->content, $asset->file_path, 'upload' );
    $asset->image_height( undef );
    $asset->image_width( undef );
    $asset->modified_by( $app->user->id );
    $asset->save or die $asset->errstr;
    $asset->remove_cached_files();
    my ( $thumbnail_url, $w, $h ) = $asset->thumbnail_url(
        Width  => 240,
    );
    $thumbnail_url .= '?' . time;
    my %data;
    $data{ thumbnail_url } = $thumbnail_url;
    $data{ width } = $w;
    $data{ height } = $h;
    my $size = $fmgr->file_size( $asset->file_path );
    $data{ size } = $size < 1024
                        ? sprintf( "%d Bytes", $size )
                        : $size < 1024000
                            ? sprintf( "%.1f KB", $size / 1024 )
                            : sprintf( "%.1f MB", $size / 1024000 );
    #return $app->json_result( \%data );
    return MT::Util::to_json( \%data );
}

1;