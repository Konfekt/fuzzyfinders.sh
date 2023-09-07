#!/bin/bash

bind -m emacs -x '"\ec": __fuzzyfinder_recent_dirs'
bind -m vi-insert -x '"\ec": __fuzzyfinder_recent_dirs'

bind -m emacs -x '"\C-t": __fuzzyfinder_recent_files'
bind -m vi-insert -x '"\C-t": __fuzzyfinder_recent_files'

# # Turn off TTY "start" and "stop" commands.
# [ -n "${TTY:-}" ] && stty -ixon <"$TTY" >"$TTY"
bind -m emacs -x '"\e\C-s": __fuzzyfinder_history'
bind -m emacs '"\C-s": "\e\C-s\e^\er"'
bind -m vi-insert -x '"\e\C-s": __fuzzyfinder_history'
bind -m vi-insert '"\C-s": "\e\C-s\e^\er"'

if [ -z "$FUZZYFINDER" ]; then
  if command -v fzf >/dev/null 2>&1; then
    FUZZYFINDER="fzf --tiebreak=index"
    [ -n "$FZF_DEFAULT_OPTS" ] && FUZZYFINDER="$FUZZYFINDER $FZF_DEFAULT_OPTS"
  elif command -v peco >/dev/null 2>&1; then
    FUZZYFINDER=peco
  elif command -v fzy >/dev/null 2>&1; then
    alias fzy='fzy --lines $LINES'
    FUZZYFINDER=fzy
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

if command -v fd > /dev/null 2>&1; then
  _recent_compgen_path() {
    cwd="${1:-"$PWD"}"
    cd "$cwd" || return 1
    (
		fd --type file --color never \
      --changed-within ${DAYS_LAST_MODIFIED}d \
      '' .  2>/dev/null;
          _compgen_path .
          ) | awk '!visited[$0]++'
        }
      else
        _recent_compgen_path() {
          cwd="${1:-"$PWD"}"
          (
          cd "$cwd" || return 1
          find . \
            -mtime -${DAYS_LAST_MODIFIED} \
            -maxdepth 5 \
            -not -path '*/\.*' -type f \( ! -iname ".*" \) \
            -printf "%C@ %p\n" 2> /dev/null |
            sort -r | cut -d ' ' -f 2- |
            sed 's@^\./@@'
                      _compgen_path .
                      ) | awk '!visited[$0]++'
                    }
fi

__fuzzyfinder_recent_files() {
	current_lbuffer="${READLINE_LINE:0:$READLINE_POINT}"
	current_rbuffer="${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}"
	# read -ra tokens <<<"$current_lbuffer"
	# num_tokens=${#tokens[@]}
	# last_token=${tokens[-1]}
	#
	# if [ -d "$last_token" ]; then
	#   current_lbuffer="${tokens[@]:1:$(( num_tokens-2 ))}"
	#   [ -n "$current_lbuffer" ] && current_lbuffer="$current_lbuffer "
	#   p="$last_token"
	# else
	#   p=.
	# fi
	p="$PWD"

	builtin typeset selected="$(_recent_compgen_path "$p" | eval "$FUZZYFINDER")"

	if [ -n "$selected" ]; then
		builtin bind '"\er": redraw-current-line'
		builtin bind '"\e^": magic-space'

		file=$(echo "$selected" | tr -d '\n')
    if [ -e "$file" ]; then
      file="$(realpath --canonicalize-missing --relative-base "$p" "$file")"
      file=$(printf %q "$file")
      file="${file/$HOME/~}"

			READLINE_LINE=$current_lbuffer${file}$current_rbuffer
			READLINE_POINT=$((READLINE_POINT + ${#file}))
    else
      return 1
    fi
	else
		builtin bind '"\er":'
		builtin bind '"\e^":'

		return 0
	fi
}

if command -v z >/dev/null 2>&1; then
  _recent_compgen_dir() {
    cwd="${1:-"$PWD"}"
    cd "$cwd" || return 1;
    (
    z -cl | sort -nr | tr -s ' ' | cut -d ' ' -f 2- |
      xargs -I{} realpath --relative-base "$cwd" {} --;
          _compgen_dir .
          ) | awk '!visited[$0]++'
        }
      else
        _recent_compgen_dir() { _compgen_dir "$1"; }
fi

__fuzzyfinder_recent_dirs() {
	current_lbuffer="${READLINE_LINE:0:$READLINE_POINT}"
	current_rbuffer="${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}"
	p="$PWD"

	builtin typeset selected="$(_recent_compgen_dir "$p" |
		eval "$FUZZYFINDER")"

	if [ -n "$selected" ]; then
		builtin bind '"\er": redraw-current-line'
		builtin bind '"\e^": magic-space'

		dir=$(echo "$selected" | tr -d '\n')
    if [ -e "$dir" ]; then
      dir="$(realpath --canonicalize-missing --relative-base "$p" "$dir")"
      dir=$(printf %q "$dir")
      dir="${dir/$HOME/~}"

			READLINE_LINE=$current_lbuffer${dir}$current_rbuffer
			READLINE_POINT=$((READLINE_POINT + ${#dir}))
    else
      return 1
    fi
	else
		builtin bind '"\er":'
		builtin bind '"\e^":'

		return 0
	fi
}

__fuzzyfinder_history() {
	local tac
	if command -v gtac >/dev/null 2>&1; then
		tac="command gtac"
	elif command -v tac >/dev/null 2>&1; then
		tac="command tac"
	else
		tac="command tail -r"
	fi

	builtin typeset READLINE_LINE_NEW="$(
	builtin fc -l -n 1 |
		eval "$tac" |
		sed 's/^\s\+//' |
		eval "$FUZZYFINDER --query \"$READLINE_LINE\""
	    )"

	    if [ -n "$READLINE_LINE_NEW" ]; then
		    builtin bind '"\er": redraw-current-line'
		    builtin bind '"\e^": magic-space'
		    READLINE_LINE=${READLINE_LINE_NEW}
		    READLINE_POINT=$((READLINE_POINT + ${#READLINE_LINE_NEW}))
	    else
		    builtin bind '"\er":'
		    builtin bind '"\e^":'
	fi
}
