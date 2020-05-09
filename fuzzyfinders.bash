#!/bin/bash

if command -v sk >/dev/null 2>&1; then
  export FUZZYFINDER="sk --reverse --tiebreak=index,score"
elif command -v fzf >/dev/null 2>&1; then
  export FUZZYFINDER="fzf --tiebreak=index"
elif command -v peco >/dev/null 2>&1; then
  export FUZZYFINDER=peco
elif command -v fzy >/dev/null 2>&1; then
  alias fzy='fzy --lines $LINES'
  export FUZZYFINDER=fzy
else
  return 1
fi

alias F="$FUZZYFINDER"

# bind -m emacs -x 
# bind -m vi-insert -x
bind -x '"\C-xh": __fuzzyfinder-history'

bind -x '"\C-xd": __fuzzyfinder-dirs'
bind -x '"\C-xf": __fuzzyfinder-files'

bind -x '"\C-xm": __fuzzyfinder-recent-files'
command -v pazi >/dev/null 2>&1 && bind -x '"\C-xr": __fuzzyfinder-recent-dirs'

__fuzzyfinder-history ()
{
  local tac
  if command -v gtac >/dev/null 2>&1; then
    tac="command gtac"
  elif command -v tac >/dev/null 2>&1; then
    tac="command tac"
  else
    tac="command tail -r"
  fi

  builtin typeset READLINE_LINE_NEW="$(
    builtin fc -l -n 1 | \
    eval "$tac" | \
    sed 's/^\s\+//' | \
    eval "$FUZZYFINDER --query \"$READLINE_LINE\""
  )"

  if [ -n "$READLINE_LINE_NEW" ]; then
    builtin bind '"\er": redraw-current-line'
    builtin bind '"\e^": magic-space'
    READLINE_LINE=${READLINE_LINE_NEW}
    READLINE_POINT=$(( READLINE_POINT + ${#READLINE_LINE_NEW} ))
  else
    builtin bind '"\er":'
    builtin bind '"\e^":'
  fi
}

__fuzzyfinder-dirs ()
{
  if command -v fd >/dev/null 2>&1; then
    builtin typeset selected="$(
      command fd -L --type directory --hidden --no-ignore --exclude .git/ --color never "" . 2>/dev/null |
      eval "$FUZZYFINDER" )"
  else
    builtin typeset selected="$(
      command find -L . \
      -name .git -prune -o -type d \
      -print 2>/dev/null |
      sed 's@^\./@@' |
      eval "$FUZZYFINDER"
    )"
  fi

  if [ -n "$selected" ]; then
    builtin bind '"\er": redraw-current-line'
    builtin bind '"\e^": magic-space'

    dir=$(echo "$selected" | tr -d '\n')
    dir=$(printf %q "$dir")
    READLINE_LINE=${READLINE_LINE:+${READLINE_LINE:0:READLINE_POINT}}${dir}${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}
    READLINE_POINT=$(( READLINE_POINT + ${#dir} ))
  else
    builtin bind '"\er":'
    builtin bind '"\e^":'
  fi
}

__fuzzyfinder-files ()
{
  if command -v fd >/dev/null 2>&1; then
    builtin typeset selected="$(command fd -L --type file --hidden --no-ignore --exclude .git/ --color never "" . 2>/dev/null |
      eval "$FUZZYFINDER")"
  elif command -v rg >/dev/null 2>&1; then
    builtin typeset selected="$(rg --glob "" --files --hidden --no-ignore --iglob !.git/ --color never "" . 2>/dev/null |
      eval "$FUZZYFINDER")"
  elif command -v ag >/dev/null 2>&1; then
    builtin typeset selected="$(ag --files-with-matches --unrestricted --ignore .git/ --nocolor --silent --filename-pattern "" . 2>/dev/null |
      eval "$FUZZYFINDER")"
  else
    builtin typeset selected="$(
      command find -L . \
      -name .git -prune -o -type f \
      -print 2>/dev/null |
      sed 's@^\./@@' |
      eval "$FUZZYFINDER"
    )"
  fi

  if [ -n "$selected" ]; then
    builtin bind '"\er": redraw-current-line'
    builtin bind '"\e^": magic-space'

    file=$(echo "$selected" | tr -d '\n')
    file=$(printf %q "$file")
    READLINE_LINE=${READLINE_LINE:+${READLINE_LINE:0:READLINE_POINT}}${file}${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}
    READLINE_POINT=$(( READLINE_POINT + ${#file} ))
  else
    builtin bind '"\er":'
    builtin bind '"\e^":'
  fi
}

if command -v pazi >/dev/null 2>&1; then
  __fuzzyfinder-recent-dirs ()
  {
    if command -v fd >/dev/null 2>&1; then
      builtin typeset selected="$(
        { pazi view | cut -f 2-;
          command fd -L --type directory --no-ignore-vcs --exclude .git/ --color never "" . 2>/dev/null; } |
        eval "$FUZZYFINDER" )"
    else
      builtin typeset selected="$(
      { pazi view | cut -f 2-; \
        command find -L . \
        -name .git -prune -o -type d \
        -print 2>/dev/null |
        sed 's@^\./@@'; } |
        eval "$FUZZYFINDER"
      )"
    fi

    if [ -n "$selected" ]; then
      builtin bind '"\er": redraw-current-line'
      builtin bind '"\e^": magic-space'

      dir=$(echo "$selected" | tr -d '\n')
      dir=$(printf %q "$dir")
      READLINE_LINE=${READLINE_LINE:+${READLINE_LINE:0:READLINE_POINT}}${dir}${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}
      READLINE_POINT=$(( READLINE_POINT + ${#dir} ))
    else
      builtin bind '"\er":'
      builtin bind '"\e^":'
    fi
  }
fi

__fuzzyfinder-recent-files () {
  builtin typeset selected="$(
    find -L . \
    -name .git -prune -o -type f \
    -printf "%C@ %p\n" 2>/dev/null |
    sort -r | cut -d ' ' -f 2- |
    sed 's@^\./@@' |
    eval "$FUZZYFINDER")"

  if [ -n "$selected" ]; then
    builtin bind '"\er": redraw-current-line'
    builtin bind '"\e^": magic-space'

    file=$(echo "$selected" | tr -d '\n')
    file=$(printf %q "$file")
    READLINE_LINE=${READLINE_LINE:+${READLINE_LINE:0:READLINE_POINT}}${file}${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}
    READLINE_POINT=$(( READLINE_POINT + ${#file} ))
  else
    builtin bind '"\er":'
    builtin bind '"\e^":'
  fi
}

