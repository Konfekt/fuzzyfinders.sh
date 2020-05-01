The files `fuzzyfinders.bash` and `fuzzyfinders.zsh` set up key bindings in `Bash` and `ZSH` to insert, right at the cursor position, a fuzzily found

- command line of the history (by default bound to `ctrl-x,h`),
- file path (by default bound to `ctrl-x,f`).
- directory path (by default bound to `ctrl-x,d`),
- the path of a recently changed file (by default bound to `ctrl-x,m`), or
- the path of a directory recently changed to or of a subdirectory in the current directory (by default bound to `ctrl-x,r`; uses [pazi](https://github.com/euank/pazi) in Bash).

For collecting all paths, whichever file searcher among `fd`, `rg` and `ag` is present, in this order, is used, before falling back to the mandatorily present command [`find`](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/find.html) (on a UNIX system, according to the `POSIX` standard).

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

# Customization

The fuzzy finder can be set by the variable `$FUZZYFINDER` and defaults, in this order, to whichever fuzzy finder among `sk`, `fzf`, `peco` and `fzy` is present.
The key bindings can be set by the first argument of the command `bind` (in `Bash`) respectively `bindkey` (in `ZSH`).

# Related

See [vim-fuzzyfinders](https://github.com/Konfekt/vim-fuzzyfinders) for the corresponding `Vim` plug-in.

# Credits

Nearly every code line was initially copied from some web page and to its original author all credit shall be due.
