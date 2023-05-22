# Git bash for windows powerline theme
#
# Licensed under MIT
# Based on https://github.com/Bash-it/bash-it and https://github.com/Bash-it/bash-it/tree/master/themes/powerline
# Some ideas from https://github.com/speedenator/agnoster-bash
# Git code based on https://github.com/joeytwiddle/git-aware-prompt/blob/master/prompt.sh
# More info about color codes in https://en.wikipedia.org/wiki/ANSI_escape_code


PROMPT_CHAR=${POWERLINE_PROMPT_CHAR:=""}
POWERLINE_LEFT_SEPARATOR=" "
POWERLINE_PROMPT="fade_in user_info scm cwd"

FADE_IN_CHAR="░▒▓"
FADE_IN_COLOR="T Bl"

USER_INFO_SSH_CHAR=" "
USER_INFO_PROMPT_COLOR="Bl Y"
USER_INFO_ROOT_COLOR="R W B"

SCM_GIT_CHAR=""
SCM_PROMPT_CLEAN=""
SCM_PROMPT_CLEAN_COLOR="G Bl"
SCM_PROMPT_COLOR=${SCM_PROMPT_CLEAN_COLOR}

CWD_PROMPT_COLOR="B W B"

function __color {
  local bg
  local fg
  local mod
  case $1 in
     'Bl') bg=40;;
     'R') bg=41;;
     'G') bg=42;;
     'Y') bg=43;;
     'B') bg=44;;
     'M') bg=45;;
     'C') bg=46;;
     'W') bg=47;;
     *) bg=49;;
  esac

  case $2 in
     'Bl') fg=30;;
     'R') fg=31;;
     'G') fg=32;;
     'Y') fg=33;;
     'B') fg=34;;
     'M') fg=35;;
     'C') fg=36;;
     'W') fg=37;;
     *) fg=39;;
  esac

  case $3 in
     'B') mod=1;;
     *) mod=0;;
  esac

  # Control codes enclosed in \[\] to not polute PS1
  # See http://unix.stackexchange.com/questions/71007/how-to-customize-ps1-properly
  echo "\[\e[${mod};${fg};${bg}m\]"
}

function __powerline_fade_in_prompt {
  echo "${FADE_IN_CHAR}|${FADE_IN_COLOR}"
}


function __powerline_user_info_prompt {
  local user_info=""
  local color=${USER_INFO_PROMPT_COLOR}
  [[ $UID -eq 0 ]] && color=${USER_INFO_ROOT_COLOR}
  if [[ -n "${SSH_CLIENT}" ]]; then
    user_info="${USER_INFO_SSH_CHAR}\u@\h"
  else
    user_info="\u@\h"
  fi
  [[ -n "${user_info}" ]] && echo "${user_info}|${color}"
}

function __powerline_cwd_prompt {
  echo "\w|${CWD_PROMPT_COLOR}"
}

function __powerline_scm_prompt {
  git_local_branch=""
  git_branch=""

  find_git_branch() {
    # Based on: http://stackoverflow.com/a/13003854/170413
    git_local_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)

    if [[ -n "$git_local_branch" ]]; then
      if [[ "$git_local_branch" == "HEAD" ]]; then
        # Branc detached Could show the hash here
        git_branch=$(git rev-parse --short HEAD 2>/dev/null)
      else
        git_branch=$git_local_branch
      fi
    else
      git_branch=""
      return 1
    fi
  }

  local color
  local scm_info

  find_git_branch

  #not in Git repo
  [[ -z "$git_branch" ]] && return

  scm_info="${SCM_GIT_CHAR}${git_branch}"
  color=${SCM_PROMPT_CLEAN_COLOR}

  [[ -n "${scm_info}" ]] && echo "${scm_info}|${color}"
}

function __powerline_left_segment {
  local OLD_IFS="${IFS}"; IFS="|"
  local params=( $1 )
  IFS="${OLD_IFS}"
  local separator_char="${POWERLINE_LEFT_SEPARATOR}"
  local separator=""
  local styles=( ${params[1]} )

  if [[ "${SEGMENTS_AT_LEFT}" -gt 1 ]]; then
    styles[1]=${LAST_SEGMENT_COLOR}
    styles[2]=""
    separator="$(__color ${styles[@]})${separator_char}"
  fi

  styles=( ${params[1]} )
  LEFT_PROMPT+="${separator}$(__color ${styles[@]})${params[0]}"

  #Save last background for next segment
  LAST_SEGMENT_COLOR=${styles[0]}
  (( SEGMENTS_AT_LEFT += 1 ))
}

function __powerline_prompt_command {
  local separator_char="${POWERLINE_PROMPT_CHAR}"

  LEFT_PROMPT=""
  SEGMENTS_AT_LEFT=0
  LAST_SEGMENT_COLOR=""

  ## left prompt ##
  for segment in $POWERLINE_PROMPT; do
    local info="$(__powerline_${segment}_prompt)"
    [[ -n "${info}" ]] && __powerline_left_segment "${info}"
  done

  [[ -n "${LEFT_PROMPT}" ]] && LEFT_PROMPT+="$(__color - ${LAST_SEGMENT_COLOR})${separator_char}$(__color)"
  # PRE="$(__color T Bl B)╭─"
  # POST="\n$(__color T Bl B)╰─ $(__color T W)"
  PRE="$(__color T Bl B)╭"
  POST="\n$(__color T Bl B)╰─ $(__color T W)"
  PS1="${PRE}${LEFT_PROMPT}${POST}"

  ## cleanup ##
  unset LAST_SEGMENT_COLOR \
        LEFT_PROMPT \
        SEGMENTS_AT_LEFT
}

function safe_append_prompt_command {
    local prompt_re

    # Set OS dependent exact match regular expression
    if [[ ${OSTYPE} == darwin* ]]; then
      # macOS
      prompt_re="[[:<:]]${1}[[:>:]]"
    else
      # Linux, FreeBSD, etc.
      prompt_re="\<${1}\>"
    fi

    if [[ ${PROMPT_COMMAND} =~ ${prompt_re} ]]; then
      return
    elif [[ -z ${PROMPT_COMMAND} ]]; then
      PROMPT_COMMAND="${1}"
    else
      PROMPT_COMMAND="${1};${PROMPT_COMMAND}"
    fi
}

safe_append_prompt_command __powerline_prompt_command

__color_matrix() {
  local buffer

  declare -A colors=([0]=black [1]=red [2]=green [3]=yellow [4]=blue [5]=purple [6]=cyan [7]=white)
  declare -A mods=([0]='' [1]=B [4]=U [5]=k [7]=N)

  # Print foreground color names
  echo -ne "       "
  for fgi in "${!colors[@]}"; do
    local fg=`printf "%10s" "${colors[$fgi]}"`
    #print color names
    echo -ne "\e[m$fg "
  done
  echo

  # Print modificators
  echo -ne "       "
  for fgi in "${!colors[@]}"; do
    for modi in "${!mods[@]}"; do
      local mod=`printf "%1s" "${mods[$modi]}"`
      buffer="${buffer}$mod "
    done
    # echo -ne "\e[m "
    buffer="${buffer} "
  done
  echo -e "$buffer\e[m"
  buffer=""

  # Print color matrix
  for bgi in "${!colors[@]}"; do
    local bgn=$((bgi + 40))
    local bg=`printf "%6s" "${colors[$bgi]}"`

    #print color names
    echo -ne "\e[m$bg "

    for fgi in "${!colors[@]}"; do
      local fgn=$((fgi + 30))
      local fg=`printf "%7s" "${colors[$fgi]}"`

      for modi in "${!mods[@]}"; do
        buffer="${buffer}\e[${modi};${bgn};${fgn}m "
      done
      # echo -ne "\e[m "
      buffer="${buffer}\e[m "
    done
    echo -e "$buffer\e[m"
    buffer=""
  done
}

__character_map () {
  echo "powerline: ±●➦★⚡★ ✗✘✓✓✔✕✖✗← ↑ → ↓"
  echo "other: ☺☻👨⚙⚒⚠⌛"
}
