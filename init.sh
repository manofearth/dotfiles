#!/bin/bash
SCRIPTDIR=$(dirname $(readlink -f $0))
ln -sf $SCRIPTDIR/bashrc ~/.bashrc
ln -sf $SCRIPTDIR/bash_aliases ~/.bash_aliases
ln -sf $SCRIPTDIR/inputrc ~/.inputrc
ln -sf $SCRIPTDIR/tmux.conf ~/.tmux.conf
ln -sf $SCRIPTDIR/vimrc ~/.vimrc
