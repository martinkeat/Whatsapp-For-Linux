#!/usr/bin/env bash
# Universal WhatsApp-for-Linux Installer Script by spontaneocus (Martin J. Keatings)
# This script will install WhatsApp Web as a desktop application on your Linux system.

set -e  # exit immediately on error (we also manually check exits for critical steps)

# Function to print a bold, boxed message for status updates
print_boxed() {
  local msg="$1"
  local cols=$(tput cols || echo 80)
  local line=$(printf '%*s' "$cols" | tr ' ' '=')
  echo -e "\e[1m${line}\e[0m"
  # Center the message within the box if possible
  local padding=$(( ($cols - ${#msg}) / 2 ))
  if [ $padding -gt 0 ]; then
    printf "\e[1m%*s%s%*s\e[0m\n" $padding "" "$msg" $padding ""
  else
    # If message is longer than line (unlikely), just print it plainly
    echo -e "\e[1m$msg\e[0m"
  fi
  echo -e "\e[1m${line}\e[0m"
}

# Detect Linux distribution from /etc/os-release
distro="unknown"
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  distro="$ID"
fi

# Set default package manager command and packages list based on distro
PM_INSTALL=""
PKG_LIST=""

case "$distro" in
  debian|ubuntu|linuxmint|elementary|pop|zorin)
    PM_INSTALL="apt-get"
    # Update apt and install dependencies
    PKG_LIST="nodejs npm curl git"
    # Include Xvfb for potential headless use
    PKG_LIST="$PKG_LIST xvfb xvfb-run"
    ;;
  fedora|rhel|centos|rocky|almalinux)
    PM_INSTALL="dnf"
    PKG_LIST="nodejs npm curl git"
    PKG_LIST="$PKG_LIST xorg-x11-server-Xvfb"
    ;;
  arch|manjaro|endeavouros)
    PM_INSTALL="pacman"
    PKG_LIST="nodejs npm curl git"
    PKG_LIST="$PKG_LIST xorg-server-xvfb"
    ;;
  opensuse*|suse)
    PM_INSTALL="zypper"
    PKG_LIST="nodejs npm curl git"
    PKG_LIST="$PKG_LIST xorg-x11-server-Xvfb"
    ;;
  alpine)
    PM_INSTALL="apk"
    PKG_LIST="nodejs npm curl git"
    PKG_LIST="$PKG_LIST xvfb xvfb-run"
    ;;
  gentoo)
    PM_INSTALL="emerge"
    PKG_LIST="nodejs npm curl git"
    # Gentoo's Xvfb is part of xorg-server with USE=headless, assume user can install if needed
    PKG_LIST="$PKG_LIST xorg-server"
    ;;
  *)
    echo "Unsupported or unrecognized Linux distribution: $distro"
    echo "Exiting. You may need to manually install: nodejs, npm, curl, git, nativefier."
    exit 1
    ;;
esac

# Use sudo for package installs if not already root
SUDO=""
if [[ $EUID -ne 0 ]]; then
  SUDO="sudo"
fi

print_boxed "Installing system dependencies..."
if [[ "$PM_INSTALL" == "apt-get" ]]; then
  $SUDO apt-get update -y
fi
# Install required packages (skip any that are already installed)
for pkg in $PKG_LIST; do
  if ! command -v ${pkg%% *} >/dev/null 2>&1; then   # check base command name
    $SUDO $PM_INSTALL -y install $pkg || { echo "Error: Failed to install $pkg. Please install it manually and re-run the script."; exit 1; }
  else
    echo "Package '$pkg' is already installed; skipping."
  fi
done

# Ensure Node.js and npm are available
if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js was not installed successfully. Exiting."
  exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
  echo "Error: npm was not installed successfully. Exiting."
  exit 1
fi

print_boxed "Installing Nativefier (npm)..."
if command -v nativefier >/dev/null 2>&1; then
  echo "Nativefier is already installed globally; skipping."
else
  $SUDO npm install -g nativefier || { echo "Error: Failed to install Nativefier via npm."; exit 1; }
fi

# Determine installation directory based on privileges
if [[ $EUID -eq 0 ]]; then
  INSTALL_DIR="/opt/WhatsApp"
else
  INSTALL_DIR="$HOME/.local/share/nativefier/WhatsApp"
fi
mkdir -p "$INSTALL_DIR"

print_boxed "Building WhatsApp desktop application with Nativefier..."
# Use nativefier to create the app (output to a temp dir if not directly to INSTALL_DIR)
BUILD_DIR="$(mktemp -d)"
# Build the WhatsApp Web app
nativefier --name "whatsapp-for-linux" --single-instance --tray "https://web.whatsapp.com" "$BUILD_DIR" >/dev/null 2>&1 || {
  echo "Error: Nativefier failed to create the WhatsApp application."
  rm -rf "$BUILD_DIR"
  exit 1
}
# The build output directory name typically ends with '-linux-x64'
APP_SUBDIR="$(find "$BUILD_DIR" -maxdepth 1 -type d -name "*-linux-x64" -print -quit)"
if [[ -z "$APP_SUBDIR" ]]; then
  # If not found, assume BUILD_DIR itself might be the app
  APP_SUBDIR="$BUILD_DIR"
fi

# Move the app to the install directory
# If INSTALL_DIR already contains an older installation, back it up
if [[ -d "$INSTALL_DIR" && "$(ls -A "$INSTALL_DIR")" ]]; then
  echo "Existing installation found in $INSTALL_DIR. Backing it up."
  mv "$INSTALL_DIR" "${INSTALL_DIR}.bak_$(date +%Y%m%d%H%M%S)" || true
  mkdir -p "$INSTALL_DIR"
fi
# Move new files in
mv "$APP_SUBDIR"/* "$INSTALL_DIR"/ 2>/dev/null || cp -r "$APP_SUBDIR"/* "$INSTALL_DIR"/
rm -rf "$BUILD_DIR"  # cleanup temp build directory

# Ensure the main executable has the expected name and is executable
# (Nativefier names the binary after the app -- "whatsapp-for-linux")
if [[ -f "$INSTALL_DIR/whatsapp-for-linux" ]]; then
  chmod +x "$INSTALL_DIR/whatsapp-for-linux"
else
  echo "Warning: Executable not found! Something went wrong with the build."
fi

# If installed as root, add a symlink for easy command-line access
if [[ $EUID -eq 0 ]]; then
  ln -sf "$INSTALL_DIR/whatsapp-for-linux" /usr/local/bin/whatsapp-for-linux
fi

print_boxed "Creating desktop launcher entry..."
LAUNCHER_DIR="$HOME/.local/share/applications"
mkdir -p "$LAUNCHER_DIR"
DESKTOP_FILE="$LAUNCHER_DIR/whatsapp-for-linux.desktop"
cat > "$DESKTOP_FILE" <<EOL
[Desktop Entry]
Name=WhatsApp
Comment=Unofficial WhatsApp Desktop client
Exec=${INSTALL_DIR}/whatsapp-for-linux %u
Icon=${INSTALL_DIR}/resources/app/icon.png
Terminal=false
Type=Application
Categories=Network;InstantMessaging;
StartupWMClass=whatsapp-for-linux
EOL

# Refresh desktop database (if available) to register the new app (optional)
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$LAUNCHER_DIR" >/dev/null 2>&1 || true
fi

# Prompt for autostart
echo ""
read -rp "Do you want WhatsApp to start automatically on login? [y/N]: " AUTOSTART_CHOICE
if [[ "$AUTOSTART_CHOICE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  AUTOSTART_DIR="$HOME/.config/autostart"
  mkdir -p "$AUTOSTART_DIR"
  cp "$DESKTOP_FILE" "$AUTOSTART_DIR/"
  echo "Autostart enabled. WhatsApp will launch at login."
else
  echo "Autostart not enabled. You can still launch WhatsApp from your applications menu or via the 'whatsapp-for-linux' command."
fi

# Headless mode setup (if no GUI detected)
if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
  echo ""
  echo "It appears you are running this script in a non-GUI environment (no DISPLAY detected)."
  read -rp "Would you like to set up WhatsApp to run headlessly in the background (using Xvfb)? [y/N]: " HEADLESS_CHOICE
  if [[ "$HEADLESS_CHOICE" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    print_boxed "Configuring headless WhatsApp service..."
    # Ensure Xvfb is installed (it should be, from earlier steps, but double-check)
    if ! command -v Xvfb >/dev/null 2>&1; then
      echo "Xvfb not found. Attempting to install Xvfb..."
      case "$distro" in
        debian|ubuntu|linuxmint|elementary|pop|zorin)
          $SUDO apt-get -y install xvfb xvfb-run ;;
        fedora|rhel|centos|rocky|almalinux)
          $SUDO dnf -y install xorg-x11-server-Xvfb ;;
        arch|manjaro|endeavouros)
          $SUDO pacman -S --noconfirm xorg-server-xvfb ;;
        opensuse*|suse)
          $SUDO zypper install -y xorg-x11-server-Xvfb ;;
        alpine)
          $SUDO apk add --no-cache xvfb xvfb-run ;;
        gentoo)
          $SUDO emerge --update --newuse xorg-server ;;
      esac
    fi
    # Create systemd service file
    SERVICE_FILE="/etc/systemd/system/whatsapp-for-linux.service"
    $SUDO bash -c "cat > $SERVICE_FILE" <<EOL2
[Unit]
Description=WhatsApp for Linux (Headless)
After=network.target

[Service]
Type=simple
User=$USER
Environment=DISPLAY=:99
ExecStart=/usr/bin/xvfb-run -a -s "-screen 0 1280x720x24" ${INSTALL_DIR}/whatsapp-for-linux
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL2
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable whatsapp-for-linux.service
    $SUDO systemctl start whatsapp-for-linux.service
    echo "Headless service installed. WhatsApp is now running in the background on a virtual display."
    echo "You can check the service status with: sudo systemctl status whatsapp-for-linux"
  fi
fi

# Final message with donation link
print_boxed "Installation complete!"
echo -e "\e[1mThank you for installing WhatsApp for Linux.\e[0m"
echo -e "If you find this application useful, please consider supporting the developer at: \e[1mhttps://paypal.me/spontaneocus\e[0m"
echo "Enjoy using WhatsApp on Linux! 🎉"
