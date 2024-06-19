# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# add user's local executables to the path
export PATH=$HOME/.local/bin:$PATH

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# check window size
[[ $DISPLAY ]] && shopt -s checkwinsize

# custom commands
alias neofetch='neofetch --ascii_colors 39 21 202 231 --source /etc/logo/archfox-neofetch.txt'
alias logo='cat /etc/logo/archfox-16bit.txt'
alias vim='nvim'
alias codi='vscodium'
alias ls='ls --color=auto'
alias l='ls -al --color=auto'

# change command prompt
PS1_c='\[\033[38;2;0;175;175;1m\]'
PS1_o='\[\033[38;2;250;125;0;1m\]'
PS1_w='\[\033[38;2;255;255;250;1m\]'
PS1_r='\[\033[0m\]'

PS1="${PS1_c}┌[${PS1_w}\u${PS1_o}@${PS1_w}\H${PS1_c}]${PS1_w}-${PS1_c}(${PS1_w}\w${PS1_c})
└> ${PS1_r}"
