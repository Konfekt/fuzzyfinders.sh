#!/bin/zsh

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

zle -N fuzzyfinder-history
bindkey "^Xh" fuzzyfinder-history

zle -N fuzzyfinder-dirs
bindkey '^Xd' fuzzyfinder-dirs

zle -N fuzzyfinder-files
bindkey '^Xf' fuzzyfinder-files

zle -N fuzzyfinder-recent-files
bindkey '^Xm' fuzzyfinder-recent-files

# Load cdr
test -n "${ZSH_CDR_DIR+x}" || ZSH_CDR_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/cdr"
test -d "$ZSH_CDR_DIR" || mkdir --parents "$ZSH_CDR_DIR"
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ':chpwd:*' recent-dirs-file "$ZSH_CDR_DIR"/recent-dirs
zstyle ':chpwd:*' recent-dirs-max 1000
zstyle ':chpwd:*' recent-dirs-default yes

if command -v cdr >/dev/null 2>&1; then
  zle -N fuzzyfinder-recent-dirs
  bindkey '^Xr' fuzzyfinder-recent-dirs
fi

fuzzyfinder-history() {
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
  local current_rbuffer="$RBUFFER"
  local tac
  if command -v gtac >/dev/null 2>&1; then
    tac="command gtac"
  elif command -v tac >/dev/null 2>&1; then
    tac="command tac"
  else
    tac="command tail -r"
  fi
  BUFFER="$(builtin fc -l -n 1 |
    eval "$tac" |
    eval "$FUZZYFINDER --query \"$LBUFFER\"")"
  BUFFER="$BUFFER""$current_rbuffer"
  CURSOR=$#BUFFER
  zle -R -c # refresh
}

fuzzyfinder-dirs() {
  setopt localoptions pipefail no_aliases 2> /dev/null
  local current_lbuffer="$LBUFFER"
  local current_rbuffer="$RBUFFER"

  tokens=("${(z)current_lbuffer}")
  last_token=${tokens[-1]}
  if [ -d "$last_token" ]; then
    current_lbuffer="${tokens[1,-2]}"
    [ -n "$current_lbuffer" ] && current_lbuffer="$current_lbuffer "
    cwd="$last_token"
  else
    cwd=.
  fi

  if command -v fd >/dev/null 2>&1; then
    local selected="$(command fd -L --type directory --hidden --no-ignore --exclude .git/ --color never "" "$cwd" 2>/dev/null |
      sed 's@^\./@@' |
      eval "$FUZZYFINDER" )"
  else
    local selected="$(
      command find -L "$cwd" \
      -name .git -prune -o -type d \
      -print 2>/dev/null |
      sed 's@^\./@@' |
      eval "$FUZZYFINDER"
    )"
  fi

  if [ -n "$selected" ]; then
    dir=$(echo "$selected" | tr -d '\n')
    dir=$(printf %q "$dir")
    BUFFER="${current_lbuffer}${dir}${current_rbuffer}"
    CURSOR=$#BUFFER
  fi
}

fuzzyfinder-files() {
  setopt localoptions pipefail no_aliases 2> /dev/null
  local current_lbuffer="$LBUFFER"
  local current_rbuffer="$RBUFFER"

  tokens=("${(z)current_lbuffer}")
  last_token=${tokens[-1]}
  if [ -d "$last_token" ]; then
    current_lbuffer="${tokens[1,-2]}"
    [ -n "$current_lbuffer" ] && current_lbuffer="$current_lbuffer "
    cwd="$last_token"
  else
    cwd=.
  fi

  if command -v fd >/dev/null 2>&1; then
    local selected="$(command fd -L --type file --hidden --no-ignore --exclude .git/ --color never "" "$cwd" 2>/dev/null | eval "$FUZZYFINDER")"
  elif command -v rg >/dev/null 2>&1; then
    local selected="$(rg --glob "" --files --hidden --no-ignore --iglob !.git/ --color never "" "$cwd" 2>/dev/null | eval "$FUZZYFINDER")"
  elif command -v ag >/dev/null 2>&1; then
    local selected="$(ag --files-with-matches --unrestricted --ignore .git/ --nocolor --silent --filename-pattern "" "$cwd" 2>/dev/null | eval "$FUZZYFINDER")"
  else
    local selected="$(
      command find -L "$cwd" \
      -name .git -prune -o -type f \
      -print 2>/dev/null |
      sed 's@^\./@@' |
      eval "$FUZZYFINDER"
    )"
  fi

  if [ -n "$selected" ]; then
    file=$(echo "$selected" | tr -d '\n')
    file=$(printf %q "$file")
    BUFFER="${current_lbuffer}${file}${current_rbuffer}"
    CURSOR=$#BUFFER
  fi
}

if command -v cdr >/dev/null 2>&1; then
  fuzzyfinder-recent-dirs () {
    setopt localoptions pipefail no_aliases 2> /dev/null
    local current_lbuffer="$LBUFFER"
    local current_rbuffer="$RBUFFER"
    if command -v fd >/dev/null 2>&1; then
      local selected="$({ cdr -l | tr -s ' ' | cut -d ' ' -f 2-; command fd -L --type directory --color never 2>/dev/null; } | eval "$FUZZYFINDER --prompt 'cdr >'")"
    else
      local selected="$({ cdr -l | tr -s ' ' | cut -d ' ' -f 2-; \
        command find -L \
        -name .git -prune -o -type d \
        -print 2>/dev/null |
        sed 's@^\./@@'; } |
        eval "$FUZZYFINDER --prompt 'cdr >'"
      )"
    fi
  if [ -n "$selected" ]; then
    dir=$(echo "$selected" | tr -d '\n')
    # only format if necessary because the paths given by cdr -l are already formatted
    [ -d "$selected" ] && dir=$(printf %q "$dir")
    BUFFER="${current_lbuffer}${dir}${current_rbuffer}"
    CURSOR=$#BUFFER
  fi
  }
fi

# From https://askubuntu.com/questions/61179/find-the-latest-file-by-modified-date/61182#61182
fuzzyfinder-recent-files () {
  setopt localoptions pipefail no_aliases 2> /dev/null
  local current_lbuffer="$LBUFFER"
  local current_rbuffer="$RBUFFER"

  tokens=("${(z)current_lbuffer}")
  last_token=${tokens[-1]}
  if [ -d "$last_token" ]; then
    current_lbuffer="${tokens[1,-2]}"
    [ -n "$current_lbuffer" ] && current_lbuffer="$current_lbuffer "
    cwd="$last_token"
    cwd="$(echo "$cwd" | sed 's@/\+$@@')"
  else
    cwd=.
  fi

  local selected="$(print -lr -- "$cwd"/**/*(omD) |
    sed 's@^\./@@' |
    eval "$FUZZYFINDER")"

  if [ -f "$selected" ]; then
    file=$(printf %q "$selected")
    BUFFER="${current_lbuffer}${file}${current_rbuffer}"
    CURSOR=$#BUFFER
  fi
}

_fuzzyfinder-man-list-all() {
  local parent dir file
  local paths=("${(s/:/)$(man --all --location)}")
  for parent in $paths; do
    for dir in $(ls -1 "$parent"); do
      local p="${parent}/${dir}"
      if [ -d "$p" ]; then
        IFS=$'\n' local lines=($(ls -1 "$p"))
        for file in $lines; do
          echo "${p}/${file}"
        done
      fi
    done
  done
}

fuzzyfinder-man() {
  local selected=$(_fuzzyfinder-man-list-all | eval "$FUZZYFINDER --prompt 'man >'")
  if [[ "$selected" != "" ]]; then
    man "$selected"
  fi
}
