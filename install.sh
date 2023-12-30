#!/bin/sh

# this script configures Vim to install Vim-Plug, packages and themes
# the theme installed is Dracula with custom color tweaks
# theme also applied to Ranger


TARGET_THEME="dracula"
DRAC_AUTOLD="$TARGET_THEME/autoload/$TARGET_THEME.vim"
DRAC_COLORS="$TARGET_THEME/colors/$TARGET_THEME.vim"
VIM_DIR="$HOME/.vim"
RANGER_DIR="$HOME/.config/ranger"


# install VimPlug
echo ""
echo "INSTALLING VimPlug"
echo "------------------------"

curl --silent --fail --location --output "$VIM_DIR/autoload/plug.vim" \
    --create-dirs "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"


# download/install minimap 
echo ""
echo "INSTALLING minimap"
echo "------------------------"

if [ `uname -m` = "aarch64" ]; then
    PKG_NAME="code-minimap"
    DEB_FILE="${PKG_NAME}_0.6.4_arm64.deb"
elif [ `uname -m` = "x86_64" ]; then
    PKG_NAME="code-minimap-musl"
    DEB_FILE="${PKG_NAME}_0.6.4_amd64.deb"
fi

installed_package=$(dpkg -l | awk '{print $2}' | grep "$PKG_NAME")

if [ "$installed_package" = "$PKG_NAME" ]; then
    echo "Package $PKG_NAME already installed."
else
    echo "Installing $PKG_NAME" 
    wget --no-verbose "https://github.com/wfxr/code-minimap/releases/download/v0.6.4/$DEB_FILE"
    sudo dpkg -i "$DEB_FILE"
    rm "$DEB_FILE"
fi


# load new vimrc + update plugins
echo "LOADING NEW vimrc FILE"
echo "------------------------"

cp "./vim/vimrc" "$VIM_DIR/"
vim +PlugInstall +qall
sleep 1


#custom theme colors 
echo "CONFIGURING VIM THEME"
echo "------------------------"

cp "vim/$DRAC_COLORS" "$VIM_DIR/plugged/$DRAC_COLORS"
cp "vim/$DRACULA/$DRAC_AUTOLD" "$VIM_DIR/plugged/$DRAC_AUTOLD"


# Install ranger theme
echo "CONFIGURING RANGER THEME"
echo "------------------------"

update_rc_setting() {
    line_text="$1"
    target_setting="$2"
    rc_file="$3"

    echo "CHECKING FOR ($line_text) SETTING in ($rc_file)"
    cur_setting=$(grep "${line_text}" "$rc_file" | awk '{print $NF}')
    if [ "$cur_setting" != "$target_setting" ]; then
        line=$(grep -n "${line_text} ${cur_setting}" "$rc_file" | cut -d: -f1)
        sed -i "${line}s/.*/${line_text} ${target_setting}/" "$rc_file"
        echo "  updated from ($cur_setting) to ($target_setting)"
    else
        echo "  (no change made)"
    fi
    echo "  $line_text -> $target_setting"
}

rc_file="$RANGER_DIR/rc.conf"
scheme="colorschemes"
cp "/etc/ranger/config/rc.conf" "$rc_file"
mkdir -p "$RANGER_DIR/$scheme"

# TODO: change to use the Xresources and ranger github repos
git clone "https://github.com/dracula/xresources.git"
cp "ranger/Xresources" "$HOME/.Xresources"

# TODO: finish
git clone "https://github.com/dracula/ranger.git"
cp "ranger/$TARGET_THEME.py" "$RANGER_DIR/$scheme/$TARGET_THEME.py"

theme_text="set colorscheme"
update_rc_setting "$theme_text" "$TARGET_THEME" "$rc_file"

border_text="set draw_borders"
target_setting="both"
update_rc_setting "$border_text" "$target_setting" "$rc_file"



echo "SCRIPT COMPLETE"

