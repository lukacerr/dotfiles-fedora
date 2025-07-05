#!bin/bash

# FUNCTIONS
install_flatpak() { sudo flatpak install -y --no-related --app $1; }
install_dnf() { sudo dnf install $1 -y --best --allowerasing --skip-broken; }
uninstall_dnf() { sudo dnf remove $1 -y; }
enable_copr() { sudo dnf copr enable $1 -y; }
install_copr() { enable_copr $1; install_dnf $2; }
tee_append() { echo "$2" | sudo tee -a $1; }

# INITIAL UNINSTALLS
uninstall_dnf "vim-minimal firewalld libreport gnome-disk-utility gnome-icon-theme system-config-language"

# RPM FUSION ADD-ON & DNF CONFIGURATION
tee_append "/etc/dnf/dnf.conf" "install_weak_deps=False"
install_dnf "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
install_dnf "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1 -y
sudo dnf update --refresh -y

# CODECS & GPU DRIVER RELATED
install_dnf "libva-utils mesa-vulkan-drivers"
sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y
sudo dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y

# FLATPAK SUPPORT
install_dnf "flatpak"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# XDG DIRS SETUP
install_dnf "xdg-utils xdg-user-dirs"
xdg-user-dirs-update --force

# TERMINAL DEFAULT CONFIG
install_dnf "alacritty fish"
sudo chsh -s $(which fish) $USER
install_copr "atim/starship" "straship"
starship preset no-nerd-font -o ~/.config/starship.toml

# NIRI INSTALLATION
install_copr "yalter/niri" "niri"
install_dnf "xdg-desktop-portal-gtk xdg-desktop-portal-gnome"
install_dnf "gnome-keyring plasma-polkit-agent"
install_dnf "xwayland-satellite"

# GRAPHICAL TARGET SETUP
install_dnf "greetd" # tuigreet
sudo systemctl enable greetd
sudo systemctl set-default graphical.target

# JOURNAL, HOST & NOPASSWD CONFIG
sudo usermod -aG systemd-journal $USER
tee_append "/etc/sudoers.d/nopasswd" "$USER ALL=(ALL:ALL) NOPASSWD: ALL"
sudo hostnamectl set-hostname $USER-pc

# FIREWALL SETUP
install_dnf "ufw"
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

# WEB BROSWER & DEFAULTS
install_copr "sneexy/zen-browser" "zen-browser"
xdg-settings set default-web-browser app.zen_browser.zen.desktop
xdg-mime default zen-browser.desktop x-scheme-handler/https x-scheme-handler/http

# DEV TOOLS SET-UP
install_dnf "git docker docker-compose"
# TODO: setear el resto; bun, rust, uv, dotnet, go
# rustup default stable
sudo usermod -aG docker $USER

# BATTERY SAVING # TODO

# EXTRA INSTALLATIONS
to_enable_copr=("atim/lazygit" "atim/lazydocker")
to_install_dnf=(
  "fastfetch btop gdu fzf brightnessctl"
  "waybar fuzzel thunar" # mpv/vlc, session bar, notif daemon
  # fcitx5 + mozc
  "nmtui" # bluetooth, audio control
  "lazygit lazydocker" # ATAC, rainfrog/dbgate/algo para db
  "libreoffice-calc libreoffice-writer" # zed editor via sh script
  "kde-connect"
  # nwg-look, kvantum manager, qt6ct ?
  "rsms-inter-fonts jetbrains-mono-nl-fonts google-noto-sans-jp-fonts"
)
for i in "${to_enable_copr[@]}"; do enable_copr $i; done
for i in "${to_install_dnf[@]}"; do install_dnf $i; done

to_install_flatpak=("md.obsidian.Obsidian" "com.obsproject.Studio")
for i in "${to_install_flatpak[@]}"; do install_flatpak $i; done

# DOTFILES SYNC
#git clone https://github.com/lukacerr/dotfiles.git && rm -rf dotfiles/.git
#cp -rfv dotfiles/. $HOME && rm -rf dotfiles
#sudo cp -rfv onRoot/. / && rm -rf onRoot
#
#sudo grub2-mkconfig -o /boot/grub2/grub.cfg
#Mark force-push.sh as executable
#sudo chmod +x force-push.sh

# dconf write /org/gnome/desktop/interface/color-scheme '"prefer-dark"'
#nwg-look -a
#gsettings set org.gnome.desktop.interface gtk-theme HyprLuka-Colloid
#gsettings set org.gnome.desktop.interface icon-theme HyprLuka-Papirus
#gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice
#gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans JP 10'
#gsettings set org.gnome.desktop.interface font-name 'Inter 11'
#gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 11'
#gsettings set org.gnome.nautilus.desktop font 'Inter 11'

# Enjoy :)
sudo dnf clean -y
sudo dnf check -y
sudo dnf autoremove -y
sudo flatpak uninstall --unused -y
sudo flatpak repair
sudo reboot

# Made by Luka Cerrutti (@lukacerr at most social media)
