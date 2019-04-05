# This expects a few things
#
# - pt for searching (https://github.com/ggreer/the_silver_searcher)
# - ctags for well tags (https://github.com/universal-ctags/ctags)
# - gocode for code completion (https://github.com/nsf/gocode)
# - goimports for code formatting on save (https://golang.org/x/tools/cmd/goimports)
# - gogetdoc for documentation display and source jump (https://github.com/zmb3/gogetdoc)
# - jq for json deserializaton, required by gogetdoc

hook global InsertCompletionShow .* %{
    map window insert <tab> <c-n>
    map window insert <s-tab> <c-p>
}
hook global InsertCompletionHide .* %{
    unmap window insert <tab> <c-n>
    unmap window insert <s-tab> <c-p>
}
hook global WinCreate ^[^*]+$ %{
    add-highlighter window/ number-lines -hlcursor
    add-highlighter global/ show-matching
    add-highlighter global/ dynregex '%reg{/}' 0:+u

    # for mark.kak
    set-face global MarkFace1 rgb:000000,rgb:FFA07A
    set-face global MarkFace2 rgb:000000,rgb:D3D3D3
    set-face global MarkFace3 rgb:000000,rgb:B0E0E6
    set-face global MarkFace4 rgb:000000,rgb:7CFC00
    set-face global MarkFace5 rgb:000000,rgb:FFD700
    set-face global MarkFace6 rgb:000000,rgb:D8BFD8
}
hook global WinSetOption filetype=go %{
    set window indentwidth 0 # 0 means real tab
    set window formatcmd 'goimports'
    set window lintcmd 'gometalinter .'
    set window makecmd 'go build .'

    add-highlighter window/ regex 'if err .*?\{.*?\}' 0:comment

    eval %sh{kak-lsp --kakoune -s $kak_session}
    lsp-start
    map window goto d <esc>:lsp-definition<ret> -docstring "Jump to definition"
    map window user d <esc>:lsp-definition<ret> -docstring "Jump to definition"
#    lsp-auto-hover-enable
    lsp-auto-hover-insert-mode-enable
    map window goto r <esc>:lsp-references<ret> -docstring "references to symbol under cursor"
    map window user k <esc>:lsp-document-symbol<ret> -docstring "Show documentation"
    map window user h <esc>:lsp-hover<ret> -docstring "Show documentation"
}
hook global WinSetOption filetype=.+ %{
    try %{ addhl global regex \<(TODO|FIXME|XXX|NOTE)\> 0:green }
}
hook global BufWritePost .*\.go %{
    go-format -use-goimports
}
hook global BufWritePre .* %{ evaluate-commands %sh{
    container=$(dirname "$kak_hook_param")
    test -d "$container" ||
    mkdir --parents "$container"
}}

def suspend-and-resume \
    -override \
    -params 1..2 \
    -docstring 'suspend-and-resume <cli command> [<kak command after resume>]' \
    %{ evaluate-commands %sh{

    nohup sh -c "sleep 0.2; xdotool type '$1'; xdotool key Return" > /dev/null 2>&1 &
    /usr/bin/kill -SIGTSTP $kak_client_pid

    if [ ! -z "$2" ]; then
        echo "$2"
    fi
}}
def findit -params 1 -shell-script-candidates %{ pt --nogroup --nocolor --column -g "" } %{ edit %arg{1} } -docstring "Uses pt to find file"
def git-edit -params 1 -shell-script-candidates %{ git ls-files } %{ edit %arg{1} } -docstring "Uses git ls-files to find files"
def mkdir %{ nop %sh{ mkdir -p $(dirname $kak_buffile) } } -docstring "Creates the directory up to this file"
def delete-buffers-matching -params 1 %{ evaluate-commands -buffer * %{ evaluate-commands %sh{ case "$kak_buffile" in $1) echo "delete-buffer" esac } } }
def -hidden text-object-indented-paragraph %{
    execute-keys -draft -save-regs '' '<a-i>pZ'
    execute-keys '<a-i>i<a-z>i'
}
def Lint %{
    map global normal <left> %{
        : lint-previous-error<ret>
    } -docstring "Prev lint error"
    map global normal <right> %{
        : lint-next-error<ret>} -docstring "Next lint error"
        lint
    } -docstring "Runs :lint and overrides <left> and <right>"
def Make %{
    map global normal <left> %{
        : make-previous-error<ret>
    } -docstring "Prev make error"
    map global normal <right> %{
        : make-next-error<ret>} -docstring "Next make error"
        make
    } -docstring "Runs :make and overrides <left> and <right>"
def Spell %{
    map global normal <left> %{: spell-replace<ret>} -docstring "Replace spelling error"
    map global normal <right> %{
        : spell-next<ret>} -docstring "Next spelling error"
        spell
    } -docstring "Runs :spell and overrides <left> and <right>"
def toggle-highlighter -params .. -docstring 'toggle-highlighter <argument>…: toggle an highlighter' %{
    try %{
        addhl window/%arg{@} %arg{@}
        echo -markup {green} %arg{@}
    } catch %{
        rmhl window/%arg{@}
        echo -markup {red} %arg{@}
    }
}
def tig-blame -override -docstring 'Open blame in tig for current file and line' %{
        suspend-and-resume "tig blame +%val{cursor_line} %val{buffile}"
}
def ide %{
    rename-client main
    set global jumpclient main
    new rename-client tools
    set global toolsclient tools
    new rename-client docs
    set global docsclient docs
}

set global grepcmd 'pt --nogroup --nocolor -e'
set global ui_options ncurses_assistant=none ncurses_enable_mouse=true ncurses_set_title=false ncurses_wheel_down_button=0
set global indentwidth 4
set global scrolloff 5,5

alias global bd delete-buffer
alias global colo colorscheme
alias global color colorscheme
alias global f findit
alias global ge git-edit
alias global qa quit
alias global qa! quit!
alias global wqa write-all-quit
alias global wqa! write-all-quit
alias global wq write-quit
alias global wq! write-quit!

map global normal <c-p> ': fzf-mode<ret>'
map global normal -docstring "Quick find" -- - %{: findit <tab>}
map global normal <down> %{: grep-next-match<ret>} -docstring "Next grep match"
map global normal <left> %{: buffer-previous<ret>} -docstring "Prev buffer"
map global normal <right> %{: buffer-next<ret>} -docstring "Next buffer"
map global normal <up> %{: grep-previous-match<ret>} -docstring "Prev grep match"
map global object h 'c<gt>,<lt><ret>' -docstring "select in the (h)tml angle brackets"
map global object b 'c\s,\s<ret>' -docstring "select (b)etween whitespace"
map global user <a-w> ':toggle-highlighter wrap -word<ret>' -docstring "toggle wordwrap"
map global user c %{: comment-line<ret>} -docstring "Comment or uncomment selected lines"
map global user M %{: mark-clear<ret>} -docstring "Remove word marking"
map global user m %{: mark-word<ret>} -docstring "Mark word with highlight"
map global user p %{| nc termbin.com 9999<ret>xyuP<a-;>k,c} -docstring "Publish to termbin.com"
map global user r %{: prompt %{Run:} %{echo %sh{tmux send-keys -t +1 "$kak_text" Enter }}<ret>} -docstring "Run command in next tmux window"
map global user t %{: nop %sh{tmux selectp -t +1}<ret>} -docstring "Switch to next tmux window"
map global user T %{: nop %sh{tmux split -v -p 20\; last-pane}<ret>} -docstring "Create new tmux window below"
map global user g %{<A-i>w,m<esc>:grep <C-r>.<ret><esc>:evaluate-commands %sh{echo rename-buffer *grep*:`uuidgen`}<ret>}

colorscheme nofrils-acme

evaluate-commands %sh{ [ -f $kak_config/local.kak ] && echo "source $kak_config/local.kak" } # machine local
try %{ source .kakrc.local } # project local

