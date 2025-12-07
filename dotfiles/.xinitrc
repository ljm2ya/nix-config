XMODIFIERS=@im=fcitx
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx

fcitx5 --replace &

xrandr --output DP-2 --primary --left-of eDP-1
xmodmap ~/.Xmodmap
exec awesome
