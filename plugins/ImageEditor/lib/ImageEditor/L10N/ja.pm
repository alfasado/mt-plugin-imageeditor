package ImageEditor::L10N::ja;
use strict;
use base qw( ImageEditor::L10N::en_us );
use utf8;

our %Lexicon = (
    'Image editor by Adobe Creative SDK on edit asset screen.'
        => 'アイテム編集画面で Adobe Creative SDK による画像エディタを利用できます。',
    '<a href="[_1]" target="_blank">Sign up Adobe Creative SDK, and create app and get Client ID on MyApps screen.</a>'
        => '<a href="[_1]" target="_blank">Adobe Creative SDK にサインアップし、MyApps からアプリケーションを作成して Client ID を取得してください。</a>',
    'Available properties are on "tools" in <a href="[_1]" target="_blank">GETTING STARTED</a> page. If empty, all tools of editor become active.'
        => '設定可能な値は <a href="[_1]" target="_blank">GETTING STARTED</a> の「tools」から確認できます。すべての機能を使用する場合は空欄にしてください。',
    'click to edit this image' => '画像を編集',
    'An error occurred during saving image as asset.' => 'アイテムとして保存中にエラーが発生しました',
    'An error occurred during downloading image.' => '画像の取得中にエラーが発生しました',
    'Client ID for Adobe Creative SDK' => 'Client ID',
    'Editor Tools' => '有効化するツール',
);

1;
