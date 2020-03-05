#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx

export PATH="$HOME/.cargo/bin:$PATH"
export DefaultImModule=fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"

# opam configuration
test -r /home/sasuseso/.opam/opam-init/init.sh && . /home/sasuseso/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true
