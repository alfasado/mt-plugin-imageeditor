package ImageEditor::Plugin;
use strict;

sub _cb_tp_edit_asset {
    my ( $cb, $app, $param ) = @_;
    my $plugin = MT->component( 'ImageEditor' );
    $param->{ imageeditor_api_key } = $plugin->get_config_value( 'api_key' );
    if ( my $tools = $plugin->get_config_value( 'tools' ) ) {
        $param->{ imageeditor_tools } = [ split( /\s*,+\s*/, $tools ) ];
    }
    my $lang;
    if ( my $author = $app->{author} ) {
        $lang = $author->preferred_language;
    }
    unless ( $lang ) {
        if ( my $blog = $app->blog ) {
            $lang = $blog->language;
        }
        $lang ||= $app->config->DefaultLanguage;
    }
    if ( $lang ) {
        $lang =~ s/^(\w\w).+/$1/;
    } else {
        $lang = 'en';
    }
    $param->{ imageeditor_lang } = $lang;
}

sub _cb_ts_edit_asset {
    my ( $cb, $app, $tmpl ) = @_;
    my $asset_id = $app->param( 'id' ) or return;
    my $asset = MT->model( 'asset' )->load( { id => $asset_id } ) or return;
    ($asset->mime_type || '') =~ m{^image/} or return;
    my $plugin = MT->component( 'ImageEditor' );
    return unless $plugin->get_config_value( 'api_key' );

    my $insert = <<'MTML';
        <__trans_section component="ImageEditor">
        <img src="<mt:var name="url" escape="html">?rev=1" id="this_image" class="hidden" />
        <script src="https://dme0ih8comzn4.cloudfront.net/imaging/v2/editor.js"></script>
        <script type="text/javascript">
        jQuery(function($) {
            var Editor,
                rev = 1,
                $this_image          = $( '#this_image' ),
                $thumb_image         = $( '#thumb_image' ),
                $file_size_formatted = $( '#file_size_formatted' ),
                $image_width         = $( '#image_width' ),
                $image_height        = $( '#image_height' );
            Editor = new Aviary.Feather( {
                apiKey: '<mt:var name="imageeditor_api_key" escape="js">', // TODO
                language: '<mt:var name="imageeditor_lang" escape="js">',
                fileFormat: '<mt:var name="file_ext">',
                <mt:loop name="imageeditor_tools" glue=", ">
                  <mt:if name="__first__">tools: [</mt:if>
                  '<mt:var name="__value__" escape="js">'
                  <mt:if name="__last__">],</mt:if>
                </mt:loop>
                onSave: function( image_id, new_url ) {
                    var org_thumb_url = $thumb_image.attr( 'src' );
                    $thumb_image.attr({ width: 40, height: 40, src: '<mt:var name="static_uri">images/indicator.gif' });
                    $.ajax( {
                        type: 'POST',
                        url: '<mt:var name="script_url">',
                        data: '__mode=replace_asset&blog_id=<mt:var name="blog_id">&id=<mt:var name="id" escape="url" escape="js">&new_url=' + encodeURIComponent(new_url),
                        success: function( json ) {
                            var thumbnail = $.parseJSON( json );
                            $thumb_image.attr( 'src', thumbnail.thumbnail_url )
                                        .removeAttr( 'width height' );
                            $file_size_formatted.text( thumbnail.size );
                            $image_width.text( thumbnail.width );
                            $image_height.text( thumbnail.height );
                            rev += 1;
                            var this_image_src = $this_image.attr( 'src' );
                            this_image_src = this_image_src.replace( /(\?rev=)\d+$/, '$1' + rev );
                            $this_image.attr( 'src', this_image_src );
                        },
                        error: function() {
                            $thumb_image.attr( 'src', org_thumb_url );
                            alert( '<__trans phrase="An error occurred during saving image as asset.">' );
                        }
                    } );
                    Editor.close();
                }
            });
            $( '.edit-nav' ).on( 'click', function () {
                Editor.launch( {
                    image: $this_image.attr("id"),
                    url: $this_image.attr("src")
                } );
            } );
        });
        </script>
        </__trans_section>
MTML
    $$tmpl =~ s/(\Q<mt:elseif name="asset_type" eq="image">\E)/$insert$1/;
    {
        my $insert = <<'MTML';
            <__trans_section component="ImageEditor">
            <a class="edit-nav" href="javascript:void(0);" title="<__trans_section component="ImageEditor"><__trans phrase="click to edit this image"></__trans_section>"><img src="<mt:staticwebpath>/images/status_icons/draft.gif"></a>
            <style type="text/css">
            .thumbnail {
                position: relative;
            }
            .edit-nav {
                position: absolute;
                bottom: 0;
                right: 0;
                background-color: #f3f3f3;
                padding: 0.1em 0.5em 0.3em 0.5em;
            }
            </style>
            </__trans_section>
MTML
        $$tmpl =~ s{(\Q<div class="thumbnail">\E)}{$1$insert}g;
    }
    {
        $$tmpl =~ s{(\Q<img src="<mt:var name="thumbnail_url" escape="html">"\E)}{$1 id="thumb_image" title="<__trans_section component="ImageEditor"><__trans phrase="click to edit this image"></__trans_section>"};
    }
    {
        $$tmpl =~ s{(\Q<mt:var name="file_size_formatted" escape="html">\E)}{<span id="file_size_formatted">$1</span>}g;
    }
    {
        $$tmpl =~ s{(\Q<mt:var name="image_width" escape="html">\E)}{<span id="image_width">$1</span>}g;
    }
    {
        $$tmpl =~ s{(\Q<mt:var name="image_height" escape="html">\E)}{<span id="image_height">$1</span>}g;
    }
}

1;
