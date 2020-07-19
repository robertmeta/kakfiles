# This expects a few things
#
#
# - rg for searching (ripgrep power!)
# - ctags for well tags (https://github.com/universal-ctags/ctags)
# - gocode for code completion (https://github.com/nsf/gocode)
# - goimports for code formatting on save (https://golang.org/x/tools/cmd/goimports)
# - gogetdoc for documentation display and source jump (https://github.com/zmb3/gogetdoc)
# - jq for json deserializaton, required by gogetdoc

# plugins
source "%val{config}/plugins/plug.kak/rc/plug.kak"
plug "occivink/kakoune-sudo-write"
plug "alexherbo2/prelude.kak"
plug "alexherbo2/connect.kak"
plug "andreyorst/smarttab.kak"
plug "fsub/kakoune-mark.git" domain "gitlab.com"
plug "occivink/kakoune-find"
plug "JJK96/kakoune-emmet"
plug "occivink/kakoune-snippets"
plug "andreyorst/fzf.kak"
# TODO: learn how to custom config path here
#plug "ul/kak-lsp" do %{
#    cargo install --locked --force --path .
#}

eval %sh{
    for tool in ag pt rg; do
        if command -V "$tool" >/dev/null 2>/dev/null; then
            printf "set global grepcmd '%s --column'\n" "$tool"
        fi
    done
}
evaluate-commands %sh{
    case $(uname) in
        Linux) printf "set global ui_options ncurses_assistant=none ncurses_enable_mouse=true ncurses_set_title=false ncurses_wheel_down_button=0" ;;
        Darwin) printf "set global ui_options ncurses_assistant=none ncurses_enable_mouse=true ncurses_set_title=false ncurses_wheel_down_button=5" ;;
    esac
}
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
addhl global/ show-whitespaces -spc ' ' -lf ' ' -nbsp '·'

hook global WinSetOption filetype=(rust|python|go|javascript|typescript|c|cpp) %{
    lsp-enable-window
    lsp-auto-hover-enable
    lsp-auto-hover-insert-mode-enable
    lsp-auto-signature-help-enable
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
    addhl global/ wrap -word -indent -marker '…'
}
hook global BufOpenFile .*\.cql$ %{
    set buffer filetype sql
    set buffer commentline --
}
hook global BufOpenFile .*\.scss$ %{
    set buffer filetype sass
}
hook global BufOpenFile .*\.hbs$ %{
    set buffer filetype handlebars
}
hook global BufNewFile .* %{ 
    editorconfig-load 
}
hook global WinSetOption filetype=sql %{
    map window user o %{: grep HACK|TODO|FIXME|XXX|NOTE|^INSERT|^UPDATE|^DELETE|^CREATE|^DROP' %val{bufname} -H -i<ret>} -docstring "Show outline"
}
hook global WinSetOption filetype=typescript %{
    set window indentwidth 2
    map window user o %{: grep HACK|TODO|FIXME|XXX|NOTE|=>|^function|^export|^enum|^static|^require|^package|^const|^class|^interface|^type %val{bufname} -H<ret>} -docstring "Show outline"
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
hook global WinSetOption filetype=sass %{
    set window indentwidth 2
    set window formatcmd 'prettier --stdin --parser css'
    hook buffer BufWritePre .* %{format}
}
hook global WinSetOption filetype=html %{
    set window indentwidth 2
    set window formatcmd 'prettier --stdin --parser html'
    hook buffer BufWritePre .* %{format}
}
hook global WinSetOption filetype=json %{
    set window indentwidth 2
    set window formatcmd 'prettier --stdin --parser json'
    hook buffer BufWritePre .* %{format}
}
hook global WinSetOption filetype=handlebars %{
    set window indentwidth 2
    set window formatcmd 'prettier --stdin --parser glimmer'
    hook buffer BufWritePre .* %{format}
}
hook global WinSetOption filetype=javascript %{
    set window indentwidth 2
    set window lintcmd 'jslint'
    map window user o %{: grep HACK|TODO|FIXME|XXX|NOTE|^function|^const|=>|^class|^interface|^type %val{bufname} -H<ret>} -docstring "Show outline"
    set window formatcmd 'prettier --stdin --parser flow'
    hook buffer BufWritePre .* %{format}
}
hook global WinSetOption filetype=markdown %{
    set window formatcmd 'prettier --stdin --parser markdown'
    hook buffer BufWritePre .* %{format}
    map window user o %{: grep HACK|TODO|FIXME|XXX|NOTE|^# %val{bufname} -H<ret>} -docstring "Show outline"
}
hook global WinSetOption filetype=go %{
    set window indentwidth 0 # 0 means real tab
    set window formatcmd 'goimports'
    set window lintcmd 'gometalinter .'
    set window makecmd 'go build .'

    add-highlighter window/ regex 'if err != nil .*?\{.*?\}' 0:comment

    map window user o %{: grep HACK|TODO|FIXME|XXX|NOTE|^func|^var|^package|^const|^goto|^struct|^type %val{bufname} -H<ret>} -docstring "Show outline"
}
hook global BufWritePost .*\.go$ %{
    go-format -use-goimports
}
hook global BufWritePre .* %{ evaluate-commands %sh{
    container=$(dirname "$kak_hook_param")
    test -d "$container" ||
    mkdir --parents "$container"
}}

define-command connect-vertical %{
    alias global terminal tmux-terminal-vertical
}
define-command connect-horizontal %{
    alias global terminal tmux-terminal-horizontal
}

define-command github-url \
    -docstring "github-url: copy the canonical GitHub URL to the system clipboard" \
    %{ evaluate-commands %sh{
        # use the remote configured for fetching
        fetch_remote=$(git config --get "branch.$(git symbolic-ref --short HEAD).remote" || printf origin)
        base_url=$(git remote get-url "$fetch_remote" | sed -e "s|^git@github.com:|https://github.com/|")
        # assume the master branch; this is what I want 95% of the time
        master_commit=$(git ls-remote "$fetch_remote" master | awk '{ print $1 }')
        relative_path=$(git ls-files --full-name "$kak_bufname")
        selection_start="${kak_selection_desc%,*}"
        selection_end="${kak_selection_desc##*,}"

        if [ "$selection_start" == "$selection_end" ]; then
            github_url=$(printf "%s/blob/%s/%s" "${base_url%.git}" "$master_commit" "$relative_path")
        else
            start_line="${selection_start%\.*}"
            end_line="${selection_end%\.*}"

            # highlight the currently selected line(s)
            if [ "$start_line" == "$end_line" ]; then
                github_url=$(printf "%s/blob/%s/%s#L%s" "${base_url%.git}" "$master_commit" "$relative_path" "${start_line}")
            else
                github_url=$(printf "%s/blob/%s/%s#L%s-L%s" "${base_url%.git}" "$master_commit" "$relative_path" "${start_line}" "${end_line}")
            fi
        fi
        printf "echo -debug %s\n" "$github_url"
        printf "execute-keys -draft '!printf %s $github_url | $kak_opt_system_clipboard_copy<ret>'\n"
        printf "echo -markup %%{{Information}copied canonical GitHub URL to system clipboard}\n"
    }
}
def nnn -params .. -file-completion %(connect-horizontal; connect-terminal nnn %arg(@)) -docstring "Open with nnn"
def ranger -params .. -file-completion %(connect-vertical; connect-terminal ranger %arg(@)) -docstring "Open with ranger"
def broot -params .. -file-completion %(connect-horizontal; connect-terminal broot %arg(@)) -docstring "Open with broot"
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

map global prompt <a-i> '<up><home>(?i)<ret>'
map global normal -docstring "Quick find" -- - %{:findit <tab>}
map global normal -docstring "Quick find" -- _ %{:broot -gc :gs<ret>}
map global normal -docstring "Quick grep" -- = %{:grep }
map global normal <down> %{: grep-next-match<ret>} -docstring "Next grep match"
map global normal <left> %{: buffer-previous<ret>} -docstring "Prev buffer"
map global normal <right> %{: buffer-next<ret>} -docstring "Next buffer"
map global normal <up> %{: grep-previous-match<ret>} -docstring "Prev grep match"
map global object h 'c<gt>,<lt><ret>' -docstring "select in the (h)tml angle brackets"
map global object b 'c\s,\s<ret>' -docstring "select (b)etween whitespace"
map global user b %{:b<space>} -docstring "Buffer select"
map global user B %{: broot<ret>} -docstring "Broot in current directory"
map global user c %{: comment-line<ret>} -docstring "Comment or uncomment selected lines"
map global user C %{:<c-r>.<ret>} -docstring "Run selected text as a command"
map global user f %{| fold -w ${kak_window_width} -s} -docstring "Fold to window width"
map global user M %{: mark-clear<ret>} -docstring "Remove word marking"
map global user m %{: mark-word<ret>} -docstring "Mark word with highlight"
map global user t %{: connect-horizontal; connect-terminal<ret>} -docstring "Start connected horizonal terminal"
map global user T %{: connect-vertical; connect-terminal<ret>} -docstring "Start connected vertical terminal"
map global user r %{: nop %sh{tmux send-keys -t {bottom-right} Up Enter }<ret>} -docstring "Rerun in bottom-right"
map global user R %{: nop %sh{tmux send-keys -t {bottom-right} C-c C-c C-c Up Enter }<ret>} -docstring "Cancel and rerun in bottom-right"
map global user n %{: e ~/gdrive/Sync/notes.md<ret>ge2o<esc><space>!date +'### %Y.%m.%d@%H:%M:%S'<ret>o<esc>} -docstring "Note a thing"
map global user z %{: nop %sh{tmux resize-pane -Z}<ret>} -docstring "Zoom window"
map global user o %{: grep HACK|TODO|FIXME|XXX|NOTE %val{bufname} -H<ret>} -docstring "Show outline"

map global user -docstring "Enable grep keymap mode for next key" g ": enter-user-mode<space>grep<ret>"
declare-user-mode grep
map global grep l %{: grep '' %val{bufname} -H<left><left><left><left><left><left><left><left><left><left><left><left><left><left><left><left><left><left>} -docstring "Local grep"
map global grep g %{<A-i>w"gy<esc>: grep <C-r>g<ret>: try %{delete-buffer *grep*:<C-r>g}<ret> : try %{rename-buffer *grep*:<C-r>g}<ret> : try %{mark-pattern set <C-r>g}<ret>} -docstring "Grep for word under cursor, persist results"
map global grep / ': exec /<ret>\Q\E<left><left>' -docstring 'regex disabled'
map global grep i %{:grep -i ''<left>} -docstring 'case insensitive'
map global grep t %{:grep -i '' -g '*.ts'<left><left><left><left><left><left><left><left><left><left><left>} -docstring 'just typescript'
map global grep k %{:grep -i '' -g '*.kt'<left><left><left><left><left><left><left><left><left><left><left>} -docstring 'just kotlin'
map global grep g %{:grep -i '' -g '*.go'<left><left><left><left><left><left><left><left><left><left><left>} -docstring 'just go'

map global user -docstring "Enable Insert keymap mode for next key" i ": enter-user-mode<space>inserts<ret>"
declare-user-mode inserts

map global inserts -docstring "comment TODO(rrm)" i %{<esc> OTODO(rrm): <esc> :comment-line<ret> }
map global inserts -docstring "comment NOTE(rrm)" n %{<esc> ONOTE(rrm): <esc> :comment-line<ret> }
map global inserts -docstring "TODO(rrm)" t %{aTODO(rrm): } 
map global inserts -docstring "Me!" R %{aRobert R Melton}

map global inserts -docstring "Date" d %{!date +'%Y.%m.%d@%H:%M:%S' <ret>}

map global user -docstring "Enable Git keymap mode for next key" G ": enter-user-mode<space>git<ret>"
declare-user-mode git
map global git -docstring "commit - Record changes to the repository" c ": git commit<ret>"
map global git -docstring "blame - Show what revision and author last modified each line of the current file" b ': connect-vertical; connect-terminal tig blame "+%val{cursor_line}" -- "%val{buffile}"<ret>,z'
map global git -docstring "blame - Show what revision and author last modified each line of the current file" B "<esc>,Gb"
map global git -docstring "diff - Show changes between HEAD and working tree" d ": git diff<ret>,z"
map global git -docstring "git - Explore the repository history" g ": repl tig<ret>"
map global git -docstring "github - Copy canonical GitHub URL to system clipboard" h ": github-url<ret>"
map global git -docstring "log - Show commit logs for the current file" l ': repl "tig log -- %val{buffile}"<ret>'
map global git -docstring "status - Show the working tree status" s ': repl "tig status"<ret>'
map global git -docstring "status - Show the working tree status" G ': repl "tig status"<ret>,z'
map global git -docstring "staged - Show staged changes" t ": git diff --staged<ret>"
map global git -docstring "write - Write and stage the current file" w ": write<ret>: git add<ret>: git update-diff<ret>"

map global user -docstring "Enable spell keymap mode for next key" s ": enter-user-mode<space>spell<ret>"
declare-user-mode spell
map global spell s ': spell<ret>' -docstring 'Check Spelling'
map global spell f ': spell-next<ret>_: enter-user-mode spell<ret>' -docstring 'next'
map global spell l ': spell-replace<ret><ret> : enter-user-mode spell<ret>' -docstring 'lucky fix'
map global spell a ': spell-replace<ret>' -docstring 'manual fix'
map global spell c ': spell-clear<ret>' -docstring 'clear'

map global user -docstring "Enable anchor keymap mode for next key" a ": enter-user-mode<space>anchor<ret>"
declare-user-mode anchor
map global anchor a '<esc><a-;>;'     -docstring 'reduce to anchor'
map global anchor c '<esc>;'          -docstring 'reduce to cursor'
map global anchor f '<esc><a-;>'      -docstring 'flip cursor and anchor'
map global anchor h '<esc><a-:><a-;>' -docstring 'ensure anchor after cursor'
map global anchor l '<esc><a-:>'      -docstring 'ensure cursor after anchor'
map global anchor s '<esc><a-S>'      -docstring 'split at cursor and anchor'

map global user -docstring "Enable option keymap mode for next key" O ": enter-user-mode<space>options<ret>"
declare-user-mode options
map global options h ': lsp-auto-hover-enable<ret>: lsp-auto-hover-insert-mode-enable<ret>'     -docstring 'enable hover help'
map global options H ': lsp-auto-hover-disable<ret>: lsp-auto-hover-insert-mode-disable<ret>'     -docstring 'disable hover help'

map global user -docstring "Enable clipboard keymap mode for next key" C ": enter-user-mode<space>clipboard<ret>"
declare-user-mode clipboard
declare-option -hidden str system_clipboard_copy ""
declare-option -hidden str system_clipboard_paste ""
evaluate-commands %sh{
    case $(uname) in
        Linux) copy="xclip -i"; paste="xclip -o" ;;
        Darwin) copy="pbcopy"; paste="pbpaste" ;;
    esac

    printf "map global clipboard -docstring 'Paste (after) from system clipboard' p '!%s<ret>'\n" "$paste"
    printf "map global clipboard -docstring 'Paste (before) from system clipboard' P '<a-!>%s<ret>'\n" "$paste"
    printf "map global clipboard -docstring 'Replace from system clipboard' R '|%s<ret>'\n" "$paste"
    printf "map global clipboard -docstring 'Yank to system clipboard' y '<a-|>%s<ret>: echo -markup %%{{Information}copied selection to system clipboard}<ret>'\n" "$copy"
    printf "map global clipboard -docstring 'Yank to system clipboard' C '<a-|>%s<ret>: echo -markup %%{{Information}copied selection to system clipboard}<ret>'\n" "$copy"
    printf "map global clipboard -docstring 'Yank to system clipboard' c '<a-|>%s<ret>: echo -markup %%{{Information}copied selection to system clipboard}<ret>'\n" "$copy"

    printf "set-option global system_clipboard_copy '%s'\n" "$copy"
    printf "set-option global system_clipboard_paste '%s'\n" "$paste"
}

map global user -docstring "Enable lsp keymap mode for next key" l ": enter-user-mode<space>lsp<ret>"

colorscheme nofrils-acme

eval %sh{kak-lsp --kakoune --config ~/.config/kak-lsp/kak-lsp.toml -s $kak_session}
map global lsp -docstring "Rename the item under cursor" R ": lsp-rename-prompt<ret>"

try %{ source ~/.kakrc.local } # system local
try %{ source .kakrc.local } # project local
