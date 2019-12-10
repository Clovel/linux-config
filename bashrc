# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# git functions for the bash prompt ---
function parse_git_branch() {
    #git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'

    # Declaring variables
    local BRANCH 
    #=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    local special_state
	local upstream
	local is_branch
	local result
	local COMMITSTATUS

	if BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null); then
		# Detached head case
		if [[ "$BRANCH" == "HEAD" ]]; then
			# Check for tag.
			BRANCH=$(git name-rev --tags --name-only $(git rev-parse HEAD))
			if ! [[ $branch == *"~"* || $branch == *" "* || $branch == undefined ]]; then
				branch="+${BRANCH}"
			else
				branch='<detached>'
				# Or show the short hash
				#branch='#'$(git rev-parse --short HEAD 2> /dev/null)
				# Or the long hash, with no leading '#'
				#branch=$(git rev-parse HEAD 2> /dev/null)
			fi
		else
			# This is a named branch.  (It might be local or remote.)
			upstream=$(git rev-parse --abbrev-ref @{upstream} 2> /dev/null | cut -f1 -d "/")
			is_branch=true
		fi

		local git_dir="$(git rev-parse --show-toplevel)/.git"

		# Check if we are in a special state
		if [[ -d "$git_dir/rebase-merge" ]] || [[ -d "$git_dir/rebase-apply" ]]; then
			special_state=rebase
		elif [[ -f "$git_dir/MERGE_HEAD" ]]; then
			special_state=merge
		elif [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]; then
			special_state=pick
		elif [[ -f "$git_dir/REVERT_HEAD" ]]; then
			special_state=revert
		elif [[ -f "$git_dir/BISECT_LOG" ]]; then
			special_state=bisect
		fi

		if [[ -n "$special_state" ]]; then
			result="{$BRANCH\\$special_state}"
		elif [[ -n "$is_branch" && -n "$upstream" ]]; then
			# Branch has an upstream

			# Comparing commits w/ upstream
			local brinfo=$(git branch -v 2> /dev/null | grep "* $BRANCH")
			local ahead=$(git rev-list --left-right --count $BRANCH...$upstream/$BRANCH | cut -f1)
			local behind=$(git rev-list --left-right --count $BRANCH...$upstream/$BRANCH | cut -f2)

			if [[ "0" != $ahead ]]; then
				COMMITSTATUS="$ahead"$'\u2197' #2197 for up
				if [[ "0" != $behind ]]; then
					COMMITSTATUS="$COMMITSTATUS $behind"$'\u2198' #2198 for down
				fi
			else
				if [[ "0" != $behind ]]; then
					COMMITSTATUS="$behind"$'\u2198' #2198 for down
				fi
			fi

			if [[ ! -z "$COMMITSTATUS" ]]; then
				result=" ($BRANCH | $COMMITSTATUS)"
			else
				result=" ($BRANCH)"
			fi

		elif [[ -n "$is_branch" ]]; then
			result=" [$BRANCH]"     # Branch has no upstream
		else
			result=" <$BRANCH>"     # Detached
		fi
	else
		result=""
	fi

	echo "$result"
}

function git_status_parse() {
	# Checking for non staged files

	if BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null); then
		if [ "$(git status -s | wc -l)" != "0" ]; then
			echo "*"
		fi
	else
		echo ""
	fi
}

export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# bash console coloring variables -----
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h\[\033[m\]:\[\033[33;1m\]\W\[\033[36;1m\]\$(parse_git_branch)\[\033[m\]\[\033[1m\]\$(git_status_parse) \[\033[m\]\$ "
export PS1
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# PATH personal modifs ----------------

# Aliases -----------------------------
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
