# Explore

[![IRC Badge]][IRC]

###### [Usage] | [Documentation] | [Contributing]

> A file and buffer explorer for [Kakoune].

![Demo]

## Installation

### [Pathogen]

``` kak
pathogen-infect /home/user/repositories/github.com/alexherbo2/explore.kak
```

## Usage

### Files

Edit a directory:

```
edit [directory]
```

With no argument, edit the parent directory of the current buffer.

- Use <kbd>Return</kbd> to edit files (works with multiple selections).
- Use <kbd>Backspace</kbd> to edit parent directory.
- Use <kbd>.</kbd> to show hidden files.
- Use <kbd>R</kbd> to show directory entries recursively.
- Use <kbd>q</kbd> to change directory and quit.
- Use <kbd>Escape</kbd> to quit.

### Buffers

Start exploring buffers by using the `buffer` command with no argument.

For ease, you can add a key-binding to your liking, like:

``` kak
map global normal b ': buffer<ret>'
```

- Use <kbd>Return</kbd> to edit selected buffer.
- Use <kbd>d</kbd> to delete selected buffer.
- Use <kbd>Backspace</kbd> to explore the parent directory of the selected buffer.
- Use <kbd>q</kbd> or <kbd>Escape</kbd> to quit.

## Configuration

### [fzf]

Explore files and buffers with [fzf] using [Connect].

``` kak
set-option global explore_files_command fzf-files
set-option global explore_buffers_command fzf-buffers
```

### [fd]

``` kak
define-command -hidden -override explore-files-recursive -params 0..1 %{
  explore-files-display "fd %sh(test $kak_opt_explore_files_show_hidden = true && echo --hidden)" %arg(1)
}
```

## Options

- `explore_files_command` `str`: File explorer command (Default: `explore-files`)
- `explore_files_show_hidden` `bool`: Whether to show hidden files (Default: `no`)
- `explore_buffers_command` `str`: Buffer explorer command (Default: `explore-buffers`)

## Faces

- `ExploreFiles` `magenta,default`: Face used to show files
- `ExploreDirectories` `cyan,default`: Face used to show directories
- `ExploreBuffers` `yellow,default`: Face used to show buffers

## Credits

Similar extensions:

- [TeddyDD]/[kakoune-edit-or-dir]
- [occivink]/[kakoune-filetree]

[Kakoune]: https://kakoune.org
[IRC]: https://webchat.freenode.net/#kakoune
[IRC Badge]: https://img.shields.io/badge/IRC-%23kakoune-blue.svg
[Demo]: images/demo.gif
[Usage]: #usage
[Documentation]: #commands
[Contributing]: CONTRIBUTING
[Pathogen]: https://github.com/alexherbo2/pathogen.kak
[Connect]: https://github.com/alexherbo2/connect.kak
[fzf]: https://github.com/junegunn/fzf
[fd]: https://github.com/sharkdp/fd
[TeddyDD]: https://github.com/TeddyDD
[kakoune-edit-or-dir]: https://github.com/TeddyDD/kakoune-edit-or-dir
[occivink]: https://github.com/occivink
[kakoune-filetree]: https://github.com/occivink/kakoune-filetree
