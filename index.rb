#!/usr/bin/ruby

# ======================================================================
# Neo's Ruby Bookmarks
#
# Neo (@Neos21) https://neos21.net/
# ======================================================================


# Bookmarklet
# ======================================================================

# javascript:(()=>{window.open('http://【HostName】/index.rb?credential=【Credential】&mode=add&title='+encodeURIComponent(document.title)+'&url='+encodeURIComponent(document.URL));})();


# Requires
# ======================================================================

require 'cgi'
require 'fileutils'


# 定数
# ======================================================================

# Private ディレクトリのパス (末尾スラッシュなし) : この配下に「クレデンシャルファイル」「シーケンスファイル」「ブックマークファイル」を配置する
PRIVATE_DIRECTORY_PATH = '../private'
# アクセスパスワードを管理するクレデンシャルファイルのパス
CREDENTIAL_FILE_PATH = "#{PRIVATE_DIRECTORY_PATH}/credential.txt"
# ブックマークのシーケンス値を保存するファイルのパス
SEQUENCE_FILE_PATH = "#{PRIVATE_DIRECTORY_PATH}/bookmarks-sequence.txt"
# ブックマーク一覧を保存するファイルのパス
BOOKMARKS_FILE_PATH = "#{PRIVATE_DIRECTORY_PATH}/bookmarks.txt"
# タイトル
PAGE_TITLE = "Neo's Ruby Bookmarks";


# グローバル変数
# ======================================================================

# CGI オブジェクト
$cgi = CGI.new


# 事前処理
# ======================================================================

def main()
  # クレデンシャルが不正な場合
  unless is_valid_credential
    print_error('Access Denied')
    return
  end
  
  # シーケンスファイルとブックマークファイルの存在チェック・なければ空ファイルを作成する
  unless File.exist?(SEQUENCE_FILE_PATH)
    File.open(SEQUENCE_FILE_PATH, 'w:UTF-8') { |sequence_file|
      sequence_file.puts('0')
    }
  end
  unless File.exist?(BOOKMARKS_FILE_PATH)
    FileUtils.touch(BOOKMARKS_FILE_PATH)
  end
  
  mode = $cgi['mode']
  if mode == 'add'
    add
  elsif mode == 'remove'
    remove
  else
    show
  end
end

# パラメータのクレデンシャルが正しいかチェックする
def is_valid_credential()
  credential_param = $cgi['credential']
  
  credential = ''
  File.open(CREDENTIAL_FILE_PATH, 'r:UTF-8') { |credential_file|
    credential = credential_file.read.chomp
  }
  
  return credential_param == credential
end


# モード別の関数
# ======================================================================

# 一覧を表示する
def show()
  print_header
  
  # 登録・削除フォーム
  print(<<"EOL")
<form action="#{ENV['SCRIPT_NAME']}" method="GET" id="add-form">
  <input type="hidden" name="credential" value="#{$cgi['credential']}">
  <input type="hidden" name="mode"       value="add">
  <p>
    <input type="text" name="title" id="add-title" value="" placeholder="Title">
    <input type="text" name="url"   id="add-url"   value="" placeholder="URL">
    <input type="button" id="add-btn" value="Add">
  </p>
</form>
<form action="#{ENV['SCRIPT_NAME']}" method="GET" id="remove-form">
  <input type="hidden" name="credential" value="#{$cgi['credential']}">
  <input type="hidden" name="mode"       value="remove">
  <input type="hidden" name="targets"    value="" id="remove-targets">
  <p>
    <input type="button" id="remove-btn"    value="Remove">
    <input type="button" id="check-all-btn" value="All">
    <span id="feedback"></span>
  </p>
</form>
EOL
  
  # 一覧表示
  is_empty = true
  File.open(BOOKMARKS_FILE_PATH, 'r:UTF-8') { |bookmarks_file|
    bookmarks_file.each_line { |line|
      if line.chomp.empty?
        next
      end
      columns  = line.chomp.split("\t")
      sequence = columns[0]
      title    = CGI.escapeHTML(columns[1])
      url      = CGI.escapeHTML(columns[2])
      print(<<"EOL")
<label class="list-item">
  <input type="checkbox" name="sequences" value="#{sequence}">
  <span>#{sequence} : </span>
  <a href="#{url}" target="_blank">[ #{title} ]</a>
</label>
EOL
      is_empty = false
    }
  }
  
  if is_empty
    puts('<p>No Bookmarks</p>')
  end
  
  print(<<"EOL")
<script>

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('add-btn').addEventListener('click', () => {
    document.getElementById('feedback').innerHTML = '';
    if(!document.getElementById('add-title').value.trim() || !document.getElementById('add-url').value.trim()) {
      document.getElementById('feedback').innerHTML = 'Title or URL is empty';
      return;
    }
    document.getElementById('add-form').submit();
  });
  
  document.getElementById('remove-btn').addEventListener('click', () => {
    document.getElementById('feedback').innerHTML = '';
    
    // チェックされているアイテムのシーケンス値をカンマ区切りで取得する
    let sequences = '';
    document.querySelectorAll('input[name="sequences"]').forEach((checkbox) => {
      if(checkbox.checked) {
        sequences += `${sequences ? ',' : ''}${checkbox.value}`;
      }
    });
    
    // 一つもチェックされていなければ何もしない
    if(!sequences) {
      document.getElementById('feedback').innerHTML = 'Please check at least 1';
      return;
    }
    
    // 隠しフォームに削除対象のシーケンス値を設定し Submit する
    document.getElementById('remove-targets').value = sequences;
    document.getElementById('remove-form').submit();
  });
  
  document.getElementById('check-all-btn').addEventListener('click', () => {
    document.querySelectorAll('input[name="sequences"]').forEach((checkbox) => {
      checkbox.checked = true;
    });
  });
});

</script>
EOL
  print_footer
end

# 追加する
def add()
  # パラメータより追加対象のページ情報を取得する
  raw_title = $cgi['title']
  raw_url   = $cgi['url']
  if raw_title.empty? || raw_url.empty?
    print_error('Add : Title or URL is empty')
    return
  end
  
  # 書き込み用にデコードする・タブ文字は適宜変換する
  title = CGI.unescape(raw_title).gsub("\t", ' ')
  url   = CGI.unescape(raw_url).gsub("\t", '%09')
  
  # 重複チェック
  is_already_added = false
  File.open(BOOKMARKS_FILE_PATH, 'r:UTF-8') { |bookmarks_file|
    bookmarks_file.each_line { |line|
      if line.chomp.empty?
        next
      end
      columns    = line.chomp.split("\t")
      line_title = columns[1]
      line_url   = columns[2]
      if line_title == title || line_url == url
        is_already_added = true
      end
    }
  }
  if is_already_added
    print_error('Add : Already added')
    return
  end
  
  # 現在のシーケンス値を取得し次のシーケンス値を作る
  next_sequence = 0
  File.open(SEQUENCE_FILE_PATH, 'r:UTF-8') { |sequence_file|
    current_sequence = sequence_file.read.chomp.to_i
    next_sequence = current_sequence + 1
  }
  
  # ブックマークに追記する
  File.open(BOOKMARKS_FILE_PATH, 'a:UTF-8') { |bookmarks_file|
    bookmarks_file.puts("#{next_sequence}\t#{title}\t#{url}")
  }
  
  # シーケンス値を更新する
  File.open(SEQUENCE_FILE_PATH, 'w:UTF-8') { |sequence_file|
    sequence_file.puts(next_sequence)
  }
  
  # 追加後は一覧にリダイレクトする
  puts($cgi.header({
    'status' => 'REDIRECT',
    'location' => create_redirect_url
  }))
end

# 削除する
def remove()
  # 削除対象のシーケンス値を取得する
  raw_targets = $cgi['targets']
  if raw_targets.empty?
    print_error('Remove : Targets not exist')
    return
  end
  
  # 削除対象のシーケンス値をカンマで区切る
  targets = raw_targets.split(',')
  
  # ブックマークファイルを開き、削除対象以外の行を取得していく
  new_text = ''
  File.open(BOOKMARKS_FILE_PATH, 'r:UTF-8') { |bookmarks_file|
    bookmarks_file.each_line { |line|
      columns  = line.chomp.split("\t")
      sequence = columns[0]
      unless targets.include?(sequence)
        new_text << line
      end
    }
  }
  
  # ファイルを更新する
  File.open(BOOKMARKS_FILE_PATH, 'w:UTF-8') { |bookmarks_file|
    bookmarks_file.puts(new_text)
  }
  
  # 削除後は一覧にリダイレクトする
  puts($cgi.header({
    'status' => 'REDIRECT',
    'location' => create_redirect_url
  }))
end


# 共通関数
# ======================================================================

# HTML のヘッダ部分を出力する
def print_header()
  print(<<"EOL")
content-type: text/html

<!DOCTYPE html>
<html lang="ja">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>#{PAGE_TITLE}</title>
    <style>

@font-face {
  font-family: "Yu Gothic";
  src: local("Yu Gothic Medium"), local("YuGothic-Medium");
}

@font-face {
  font-family: "Yu Gothic";
  src: local("Yu Gothic Bold"), local("YuGothic-Bold");
  font-weight: bold;
}

*,
::before,
::after {
  box-sizing: border-box;
}

html {
  font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Helvetica, YuGothic, "Yu Gothic", "Hiragino Sans", "Hiragino Kaku Gothic ProN", Meiryo, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
  text-decoration-skip-ink: none;
  -webkit-text-size-adjust: 100%;
  -webkit-text-decoration-skip: objects;
  word-break: break-all;
  line-height: 1.5;
  background: #000;
  overflow: hidden scroll;
  cursor: default;
}

html,
a {
  color: #0d0;
}

h1 {
  font-size: 1rem;
}

h1 a {
  text-decoration: none;
}

h1 a:hover {
  text-decoration: underline;
}

input {
  margin: 0;
  border: 1px solid #0c0;
  border-radius: 0;
  padding: .25rem .5rem;
  color: inherit;
  font-size: 1rem;
  font-family: inherit;
  background: transparent;
  vertical-align: top;
  outline: none;
}

input::placeholder {
  color: #090;
}

#add-form > p {
  display: grid;
  grid-template: "add-title add-submit" auto
                 "add-url   add-submit" auto
                 / 1fr auto;
}

#add-form > p > input:nth-child(1) {
  grid-area: add-title;
}

#add-form > p > input:nth-child(2) {
  grid-area: add-url;
  border-top: 0;
}

#add-form > p > input:nth-child(3) {
  grid-area: add-submit;
  border-left: 0;
}

#remove-form > p {
  margin-top: 1.5rem;
}

#remove-form > p > #feedback {
  margin-left: 1rem;
  font-weight: bold;
  vertical-align: bottom;
}

.list-item {
  display: grid;
  grid-template: auto / auto auto 1fr;
  align-items: start;
}

.list-item > input {
  position: relative;
  top: .25rem;
}

.list-item > span {
  margin-left: .5rem;
  margin-right: 1rem;
}

    </style>
  </head>
  <body>
EOL
end

# HTML のフッタ部分を出力する
def print_footer()
  print(<<'EOL')
  </body>
</html>
EOL
end

# エラーメッセージを表示する
def print_error(message)
  print_header
  print(<<"EOL")
<h1>#{PAGE_TITLE}</h1>
<p><strong>#{message}</strong></p>
EOL
  print_footer
end

# リダイレクト用 URL を生成する
def create_redirect_url()
  port = ENV['SERVER_PORT'] == '80' ? '' : ":#{ENV['SERVER_PORT']}"
  return "http://#{ENV['SERVER_NAME']}#{port}#{ENV['SCRIPT_NAME']}?credential=#{$cgi['credential']}"
end


# 実行
# ======================================================================

main
