#!/bin/zsh

zle -N fuzzyfinder-recent-files
bindkey '^T' fuzzyfinder-recent-files

zle -N fuzzyfinder-recent-dirs
bindkey '\ec' fuzzyfinder-recent-dirs

zle -N fuzzyfinder-history
bindkey "^S" fuzzyfinder-history

if [ -z "$FUZZYFINDER" ]; then
  if command -v fzf >/dev/null 2>&1; then
    FUZZYFINDER="fzf --tiebreak=index"
    [ -n "$FZF_DEFAULT_OPTS" ] && FUZZYFINDER="$FUZZYFINDER $FZF_DEFAULT_OPTS"
  elif command -v fzy >/dev/null 2>&1; then
    alias fzy='fzy --lines $LINES'
    FUZZYFINDER=fzy
  elif command -v peco >/dev/null 2>&1; then
    FUZZYFINDER=peco
  else
    return 1
  fi
fi

[ -z "$DAYS_LAST_MODIFIED" ] && DAYS_LAST_MODIFIED=7

if ! command -v _compgen_path >/dev/null 2>&1; then
  if command -v fd >/dev/null 2>&1; then
	  _compgen_path() {
		  command fd --type file --hidden --no-ignore --exclude '.{git,hg,bzr,svn}/' --color never '' "$@" 2>/dev/null
	  }
  elif command -v rg >/dev/null 2>&1; then
	  _compgen_path() {
		  rg --files --hidden --no-ignore --iglob '!.{git,hg,bzr,svn}/' --color never --glob '' '' "$@" 2>/dev/null
	  }
  elif command -v ag >/dev/null 2>&1; then
	  _compgen_path() {
	    ag --files-with-matches --unrestricted --ignore .git/ --nocolor --silent --filename-pattern '' '' "$@" 2>/dev/null
	  }
  else
	  _compgen_path() {
		  command find "$1" \
			  -name .git -prune -o \( -type d -o -type f -o -type l \) \
			  -a -not -path "$1" -print 2>/dev/null | sed 's@^\./@@'
	    }
  fi
fi

if ! command -v _compgen_dir >/dev/null 2>&1; then
  if command -v fd >/dev/null 2>&1; then
	  _compgen_dir() {
		  command fd --type directory --hidden --no-ignore --exclude '.{git,hg,bzr,svn}/' --color never "" "$@" 2>/dev/null
	  }
  else
	  _compgen_dir() {
		  command find "$@" \
			  -name .git -prune -o -type d \
			  -a -not -path "${@: -1}" -print 2>/dev/null | sed 's@^\./@@'
	    }
  fi
fi

if command -v fd >/dev/null 2>&1; then
  _recent_compgen_path() {
    cwd="${1:-"$PWD"}"
    cd "$cwd" || return 1;
    (
		fd --type file --color never \
      --changed-within ${DAYS_LAST_MODIFIED}d \
      '' .  2>/dev/null;
          _compgen_path .;
          ) | awk '!visited[$0]++'

        }
      else
        _recent_compgen_path() {
          cwd="${1:-"$PWD"}"
          cd "$cwd" || return 1;
          (
		      find . \
		        -mtime -${DAYS_LAST_MODIFIED} \
		        -maxdepth 5 \
            -not -path '*/\.*' -type f \( ! -iname ".*" \) \
		        -printf "%C@ %p\n" 2>/dev/null |
		        sort -r | cut -d ' ' -f 2- |
		        sed 's@^\./@@';
                      _compgen_path .;
                      ) | awk '!visited[$0]++'
                    }
fi

fuzzyfinder-recent-files() {
  setopt localoptions pipefail no_aliases 2> /dev/null
  local current_lbuffer="$LBUFFER"
  local current_rbuffer="$RBUFFER"

  tokens=("${(z)current_lbuffer}")
  last_token=${tokens[-1]}
  last_token="${last_token/\~/$HOME}"

  if [ -d "$last_token" ]; then
    current_lbuffer="${tokens[1,-2]}"
    [ -n "$current_lbuffer" ] && current_lbuffer="$current_lbuffer "

    p="$last_token"
  else
    p="$PWD"
  fi
  # remove trailing slashes
  p="$(realpath --canonicalize-missing "$p")"

  local selected="$(_recent_compgen_path "$p" | eval "$FUZZYFINDER")"

  if [ -n "$selected" ]; then
    file=$(echo "$selected" | tr -d '\n')

    if ( cd "$p" && [ -e "$file" ] ); then
      cwd="$PWD"
      file="$(cd "$p" && realpath --canonicalize-missing --relative-base "$cwd" "$file")"
      file=$(printf %q "$file")
      file="${file/$HOME/~}"

      BUFFER="${current_lbuffer}${file}${current_rbuffer}"
      CURSOR=$#BUFFER
    else
      return 1
    fi
  else
    return 0
  fi
}

if command -v z >/dev/null 2>&1; then
  _recent_compgen_dir() {
    cwd="${1:-"$PWD"}"
    cd "$cwd" || return 1;
    (
    z -cl | sort -nr | tr -s ' ' | cut -d ' ' -f 2- |
      xargs -I{} realpath --relative-base "$cwd" {} --
          _compgen_dir .
          ) | awk '!visited[$0]++'
        }
      else
        # Load cdr if available
        test -n "${ZSH_CDR_DIR}" || ZSH_CDR_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/sh/zsh/cdr"
        [ -d "$ZSH_CDR_DIR" ] || mkdir --parents --verbose "$ZSH_CDR_DIR"
        autoload -Uz chpwd_recent_dirs cdr
        autoload -U add-zsh-hook
        add-zsh-hook chpwd chpwd_recent_dirs
        zstyle ':chpwd:*' recent-dirs-file "$ZSH_CDR_DIR"/recent-dirs
        zstyle ':chpwd:*' recent-dirs-max 2500
        # fall through to cd
        zstyle ':chpwd:*' recent-dirs-default yes
        zstyle ':chpwd:*' recent-dirs-prune 'pattern:/tmp(|/*)'

        if command -v cdr >/dev/null 2>&1; then
          _recent_compgen_dir() {
            cwd="${1:-"$PWD"}"
            (
            cdr -l | sort -nr | tr -s ' ' | cut -d ' ' -f 2- |
              grep -F "$(realpath --canonicalize-missing -- "$cwd")" |
              xargs -I{} realpath --relative-base "$cwd" {} --;
                          _compgen_dir "$cwd"
                          ) | awk '!visited[$0]++'
                        }
                      else
                        _recent_compgen_dir() { _compgen_dir "$1"; }
        fi
fi

fuzzyfinder-recent-dirs () {
  setopt localoptions pipefail no_aliases 2> /dev/null
  local current_lbuffer="$LBUFFER"
  local current_rbuffer="$RBUFFER"

  tokens=("${(z)current_lbuffer}")
  last_token=${tokens[-1]}
  last_token="${last_token/\~/$HOME}"

  if [ -d "$last_token" ]; then
    current_lbuffer="${tokens[1,-2]}"
    [ -n "$current_lbuffer" ] && current_lbuffer="$current_lbuffer "

    p="$last_token"
  else
    p="$PWD"
  fi
  # remove trailing slashes
  p="$(realpath --canonicalize-missing "$p")"

  local selected="$( _recent_compgen_dir "$p" | eval "$FUZZYFINDER")"

  if [ -n "$selected" ]; then
    dir=$(echo "$selected" | tr -d '\n')

    if ( cd "$p" && [ -e "$dir" ] ); then
      cwd="$PWD"
      dir="$(cd "$p" && realpath --canonicalize-missing --relative-base "$cwd" "$dir")"
      dir=$(printf %q "$dir")
      dir="${dir/$HOME/~}"

      BUFFER="${current_lbuffer}${dir}${current_rbuffer}"
      CURSOR=$#BUFFER
    else
      return 1
    fi
  else
    return 0
  fi
}

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
      if [ -n "$selected" ]; then
        man "$selected"
      fi
}
