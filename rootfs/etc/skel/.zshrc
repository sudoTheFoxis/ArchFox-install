export ZSH="$HOME/.zsh"

# custom commands
alias neofetch='neofetch --ascii_colors 39 21 202 231 --source /etc/logo/archfox-colors.txt'
alias logo='cat /etc/logo/archfox-16bit.txt'
alias ls='ls --color=auto'
alias l='ls --color=auto -alh'

# change command prompt
PROMPT_c='[38;2;0;175;175;1m'
PROMPT_o='[38;2;250;125;0;1m'
PROMPT_w='[38;2;255;255;250;1m'
PROMPT_r='[0m'

PROMPT="%{$PROMPT_c%}┌[%{$PROMPT_w%}%n%{$PROMPT_c%}@%{$PROMPT_w%}%m%{$PROMPT_c%}]%{$PROMPT_o%}-%{$PROMPT_c%}(%{$PROMPT_w%}%d%{$PROMPT_c%})
└> % %{$PROMPT_r%}"

## plugins
#source $ZSH/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
