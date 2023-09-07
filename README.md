The shell scripts `fuzzyfinders.bash` and `fuzzyfinders.zsh` set up key bindings in `Bash` and `ZSH` to insert, at the cursor position, a fuzzily found

- command line of the history (by default bound to `Ctrl-S`),
- file path (by default bound to `Ctrl-T`), listing first the recently (in the last `$DAYS_LAST_MODIFIED`) modified files,
- the path of a subdirectory in the current directory (by default bound to `Alt-C`), listing first those recently changed to;
     uses either [z.sh](https://github.com/rupa/z) or [z.lua](https://github.com/skywind3000/z.lua), falls back to the in-built [cdr](https://github.com/zsh-users/zsh/blob/master/Functions/Chpwd/cdr) in ZSH.

The file paths are listed among those inside the current working directory;
in `ZSH`, optionally inside those after the path before the cursor position.

The fuzzy finder can be set by the variable `$FUZZYFINDER` and defaults, in this order, to the first fuzzy finder found among [fzf](https://github.com/junegunn/fzf/), [peco](https://github.com/peco/peco/) and [fzy](https://github.com/jhawthorn/fzy).

The functions `_compgen_path` (for files) and `_compgen_dir` (for directories) collect all paths and use by default the first file searcher among [fd](https://github.com/sharkdp/fd), [ripgrep](https://github.com/BurntSushi/ripgrep) and [ag](https://github.com/ggreer/the_silver_searcher), before falling back to the mandatorily present command [`find`](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/find.html) (on a UNIX system, according to the `POSIX` standard).

# Installation

1. Save these scripts, say to `~/.config/sh`, and mark them executable by

    ```sh
    mkdir ~/Downloads
    cd ~/Downloads
    git clone https://github.com/Konfekt/fuzzyfinders.sh
    mkdir --parents ~/.config/sh
    cp ~/Downloads/fuzzyfinders.sh/fuzzyfinders.{bash,zsh} ~/.config/sh
    chmod a+x ~/.config/sh/fuzzyfinders.{bash,zsh}
    ```

1. Source them on shell startup by adding to the shell configuration file

    - which is `~/.profile` for Bash, the line

    ```sh
    . "$HOME/.config/sh/fuzzyfinders.bash"
    ```

    - respectively `~/.zshrc` for ZSH, the line

    ```sh
    . "$HOME/.config/sh/fuzzyfinders.zsh"
    ```

1. To use the `Ctrl-S` binding, add `[ -n "${TTY:-}" ] && stty -ixon <"$TTY" >"$TTY"` to your `~/.bashrc` respectively `unsetopt FLOW_CONTROL` to your `.zshrc`.

# Customization

The fuzzy finder can be set by the variable `$FUZZYFINDER` and defaults, in this order, to whichever fuzzy finder among `sk`, `fzf`, `peco` and `fzy` is present.
The number of days for a file to be considered recently modified can by set by the variable `$DAYS_LAST_MODIFIED`

The key bindings can be set by the first argument of the command `bind` (in `Bash`) respectively `bindkey` (in `ZSH`).

# Related

See [vim-fuzzyfinders](https://github.com/Konfekt/vim-fuzzyfinders) for the corresponding `Vim` plug-in.
