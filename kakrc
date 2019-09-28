# This expects a few things
#
#
# - rg for searching (ripgrep power!)
# - ctags for well tags (https://github.com/universal-ctags/ctags)
# - gocode for code completion (https://github.com/nsf/gocode)
# - goimports for code formatting on save (https://golang.org/x/tools/cmd/goimports)
# - gogetdoc for documentation display and source jump (https://github.com/zmb3/gogetdoc)
# - jq for json deserializaton, required by gogetdoc
eval %sh{
    for tool in ag pt rg; do
        if command -V "$tool" >/dev/null 2>/dev/null; then
            printf "set global grepcmd '%s --column'\n" "$tool"
        fi
    done
}
set global ui_options ncurses_assistant=none ncurses_enable_mouse=true ncurses_set_title=false ncurses_wheel_down_button=0
set global scrolloff 5,5

# Indent
set global indentwidth 4
hook global InsertChar \t %{ try %{
    execute-keys -draft "h<a-h><a-k>\A\h+\z<ret><a-;>;%opt{indentwidth}@"
}}
hook global InsertDelete ' ' %{ try %{
    execute-keys -draft 'h<a-h><a-k>\A\h+\z<ret>i<space><esc><lt>'
}}
hook global InsertCompletionShow .* %{
    try %{
        # this command temporarily removes cursors preceded by whitespace;
        # if there are no cursors left, it raises an error, does not
        # continue to execute the mapping commands, and the error is eaten
        # by the `try` command so no warning appears.
        execute-keys -draft 'h<a-K>\h<ret>'
        map window insert <tab> <c-n>
        map window insert <s-tab> <c-p>
    }
}
hook global InsertCompletionHide .* %{
    unmap window insert <tab> <c-n>
    unmap window insert <s-tab> <c-p>
}

set-face global MarkFace1 rgb:000000,rgb:00FF4D
set-face global MarkFace2 rgb:000000,rgb:F9D3FA
set-face global MarkFace3 rgb:000000,rgb:A3B3FF
set-face global MarkFace4 rgb:000000,rgb:BAF2C0
set-face global MarkFace5 rgb:000000,rgb:FBAEB2
set-face global MarkFace6 rgb:000000,rgb:FBFF00

add-highlighter global/ dynregex '%reg{/}' 0:+u
add-highlighter global/ number-lines -hlcursor
add-highlighter global/ show-matching
addhl global/ regex 'HACK|TODO|FIXME|XXX|NOTE' 0:+rb
addhl global/ show-whitespaces -spc ' '

hook global WinSetOption filetype=(rust|python|go|javascript|typescript|c|cpp) %{
    lsp-enable-window
    lsp-auto-hover-enable
    lsp-auto-hover-insert-mode-enable
    lsp-auto-hover-signature-help-enable
    map window user o %{: grep HACK|TODO|FIXME|XXX|NOTE|^\w+ %val{bufname} -H<ret>} -docstring "Show outline"

}
hook global WinCreate .* %{
    hook window InsertCompletionShow .* %{
        map window insert <tab> <c-n>
        map window insert <s-tab> <c-p>
    }
    hook window InsertCompletionHide .* %{
        unmap window insert <tab> <c-n>
        unmap window insert <s-tab> <c-p>
    }
}
hook global BufOpenFile .* %{
    editorconfig-load
}
hook global BufOpenFile .*\.cql$ %{
    set buffer filetype sql
    set buffer commentline --
}
hook global BufNewFile .* %{ 
    editorconfig-load 
}
hook global WinSetOption filetype=sql %{
    map window user o %{: grep HACK|TODO|FIXME|XXX|NOTE|^INSERT|^UPDATE|^DELETE|^CREATE|^DROP' %val{bufname} -H -i<ret>} -docstring "Show outline"
}
hook global WinSetOption filetype=typescript %{
    set window indentwidth 2
    map window user o %{: grep HACK|TODO|FIXME|XXX|NOTE|^function|^export|^enum|^static|^require|^import|^package|^const|^class|^interface|^import|^type %val{bufname} -H<ret>} -docstring "Show outline"
    set window lintcmd 'tslint'
    set window formatcmd 'prettier --stdin --parser typescript'
    hook buffer BufWritePre .* %{format}

    map window inserts c %{iconsole.log('X', JSON.stringify(X))<esc><a-/>X<ret><a-n>c} -docstring %{console.log}
}
hook global WinSetOption filetype=css %{
    set window indentwidth 2
    set window formatcmd 'prettier --stdin --parser css'
    hook buffer BufWritePre .* %{format}
}
hook global WinSetOption filetype=json %{
    set window indentwidth 2
    set window formatcmd 'prettier --stdin --parser json'
    hook buffer BufWritePre .* %{format}
}
hook global WinSetOption filetype=javascript %{
    set window indentwidth 2
    set window lintcmd 'jslint'
    map window user o %{: grep HACK|TODO|FIXME|XXX|NOTE|^function|^const|^class|^interface|^import|^type %val{bufname} -H<ret>} -docstring "Show outline"
    set window formatcmd 'prettier --stdin --parser javascript'
    hook buffer BufWritePre .* %{format}
}
hook global WinSetOption filetype=markdown %{
    set window formatcmd 'prettier --stdin --parser javascript'
    hook buffer BufWritePre .* %{format}
}
hook global WinSetOption filetype=go %{
    set window indentwidth 0 # 0 means real tab
    set window formatcmd 'goimports'
    set window lintcmd 'gometalinter .'
    set window makecmd 'go build .'

    add-highlighter window/ regex 'if err != nil .*?\{.*?\}' 0:comment

    map window user o %{: grep HACK|TODO|FIXME|XXX|NOTE|^func|^import|^var|^package|^const|^goto|^struct|^type %val{bufname} -H<ret>} -docstring "Show outline"
}
hook global BufWritePost .*\.go$ %{
    go-format -use-goimports
}
hook global BufWritePre .* %{ evaluate-commands %sh{
    container=$(dirname "$kak_hook_param")
    test -d "$container" ||
    mkdir --parents "$container"
}}

def nnn -params .. -file-completion %(connect nnn %arg(@)) -docstring "Open with nnn"
def findit -params 1 -shell-script-candidates %{ rg --files } %{ edit %arg{1} } -docstring "Uses rg to find file"
def git-edit -params 1 -shell-script-candidates %{ git ls-files } %{ edit %arg{1} } -docstring "Uses git ls-files to find files"
def mkdir %{ nop %sh{ mkdir -p $(dirname $kak_buffile) } } -docstring "Creates the directory up to this file"
def delete-buffers-matching -params 1 %{ evaluate-commands -buffer * %{ evaluate-commands %sh{ case "$kak_buffile" in $1) echo "delete-buffer" esac } } }
def toggle-highlighter -params .. -docstring 'toggle-highlighter <argument>…: toggle an highlighter' %{
    try %{
        addhl window/%arg{@} %arg{@}
        echo -markup {green} %arg{@}
    } catch %{
        rmhl window/%arg{@}
        echo -markup {red} %arg{@}
    }
}
def ide %{
    rename-client main
    set global jumpclient main
    new rename-client tools
    set global toolsclient tools
}

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
map global user t %{: connect-terminal<ret>} -docstring "Start connected terminal"
map global user r %{: nop %sh{tmux send-keys -t {bottom-right} Up Enter }<ret>} -docstring "Rerun in bottom-right"
map global user R %{: %sh{tmux send-keys -t {bottom-right} C-c C-c C-c Up Enter }<ret>} -docstring "Cancel and rerun in bottom-right"
map global user e %{: expand<ret>} -docstring "Expand selection"
map global user o %{: enter-user-mode split-object<ret>} -docstring "Enable split object keymap mode for next key"
map global user n %{: nnn .<ret>} -docstring "Run nnn file browser"

map global user -docstring "Enable search keymap mode for next key" s ": enter-user-mode<space>search<ret>"
declare-user-mode search
map global search l %{: grep '' %val{bufname} -H<left><left><left><left><left><left><left><left><left><left><left><left><left><left><left><left><left><left>} -docstring "Local grep"
map global search g %{<A-i>w"gy<esc>: grep <C-r>g<ret>: try %{delete-buffer *grep*:<C-r>g}<ret> : try %{rename-buffer *grep*:<C-r>g}<ret> : try %{mark-pattern set <C-r>g}<ret>} -docstring "Grep for word under cursor, persist results"
map global search s %{<A-i>w"gy<esc>: grep <C-r>g<ret>: try %{delete-buffer *grep*:<C-r>g}<ret> : try %{rename-buffer *grep*:<C-r>g}<ret> : try %{mark-pattern set <C-r>g}<ret>} -docstring "Grep for word under cursor, persist results"
map global search / ': exec /<ret>\Q\E<left><left>' -docstring 'regex disabled'
map global search i '/(?i)'                         -docstring 'case insensitive'

map global user -docstring "Enable Insert keymap mode for next key" i ": enter-user-mode<space>inserts<ret>"
declare-user-mode inserts
map global inserts -docstring "TODO" t %{iTODO(rrm): } 
map global inserts -docstring "TODO" i %{iTODO(rrm): } 
map global inserts -docstring "Name" n %{iRobert R Melton}
map global inserts -docstring "Date" d %{!date<ret>}

map global user -docstring "Enable Git keymap mode for next key" g ": enter-user-mode<space>git<ret>"
declare-user-mode git
map global git -docstring "commit - Record changes to the repository" c ": git commit<ret>"
map global git -docstring "blame - Show what revision and author last modified each line of the current file" b ': connect "tig blame -C +%val{cursor_line} -- %val{buffile}"<ret>'
map global git -docstring "diff - Show changes between HEAD and working tree" d ": git diff<ret>"
map global git -docstring "git - Explore the repository history" g ": connect tig<ret>"
map global git -docstring "log - Show commit logs for the current file" l ': connect "tig log -- %val{buffile}"<ret>'
map global git -docstring "status - Show the working tree status" s ': connect "tig status"<ret>'
map global git -docstring "status - Show the working tree status" g ': connect "tig status"<ret>'
map global git -docstring "staged - Show staged changes" t ": git diff --staged<ret>"
map global git -docstring "write - Write and stage the current file" w ": write<ret>: git add<ret>: git update-diff<ret>"

map global user -docstring "Enable anchor keymap mode for next key" a ": enter-user-mode<space>anchor<ret>"
declare-user-mode anchor
map global anchor a '<esc><a-;>;'     -docstring 'reduce to anchor'
map global anchor c '<esc>;'          -docstring 'reduce to cursor'
map global anchor f '<esc><a-;>'      -docstring 'flip cursor and anchor'
map global anchor h '<esc><a-:><a-;>' -docstring 'ensure anchor after cursor'
map global anchor l '<esc><a-:>'      -docstring 'ensure cursor after anchor'
map global anchor s '<esc><a-S>'      -docstring 'split at cursor and anchor'

map global user -docstring "Enable lsp keymap mode for next key" l ": enter-user-mode<space>lsp<ret>"

colorscheme nofrils-acme

eval %sh{kak-lsp --kakoune --config ~/.config/kak-lsp/kak-lsp.toml -s $kak_session}

try %{ source ~/.kakrc.local } # system local
try %{ source .kakrc.local } # project local
