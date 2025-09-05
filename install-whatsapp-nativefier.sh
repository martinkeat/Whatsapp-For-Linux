#!/usr/bin/env bash
#Script Created by Spontaneocus (aka Martin J Keatings)

# WhatsApp Web Nativefier Installer Script
# Supports top Linux distributions (Ubuntu/Debian, Fedora/RHEL, Arch/Manjaro, openSUSE, etc.):contentReference[oaicite:0]{index=0}.
# This script installs Node.js (via appropriate package manager/repository):contentReference[oaicite:1]{index=1}, Nativefier, and sets up WhatsApp Web as a desktop app.
# It creates a .desktop launcher and autostart entry for graphical login, and can optionally configure headless (Xvfb) mode.

set -e  # Exit on any error
trap 'echo -e "\033[1;31mERROR:\033[0m Installation failed. Please check the output for issues."' ERR

# Function to print a bold boxed message for status updates
print_box() {
  local msg="$*"
  local inner=" $msg "
  local border_line="+$(printf '%.0s-' $(seq 1 ${#inner}))+"
  echo -e "\033[1m$border_line\033[0m"
  echo -e "\033[1m|$inner|\033[0m"
  echo -e "\033[1m$border_line\033[0m"
}

# Determine distribution and package manager
dist_id="unknown"
pkg_mgr="unknown"
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  dist_id="$ID"
  # Use ID_LIKE if available for distros like Pop!_OS, Zorin, etc. that are based on Ubuntu/Debian:contentReference[oaicite:2]{index=2}.
  [[ "$dist_id" == "zorin" || "$dist_id" == "pop" || "$dist_id" == "linuxmint" || "$dist_id" == "elementary" ]] && dist_id="ubuntu"
  if [[ -n "$ID_LIKE" && "$pkg_mgr" == "unknown" ]]; then
    case "$ID_LIKE" in
      *debian*|*ubuntu*) dist_id="ubuntu" ;;
      *rhel*|*fedora*|*centos*) dist_id="fedora" ;;
      *suse*) dist_id="suse" ;;
      *arch*) dist_id="arch" ;;
    esac
  fi
fi

# Map distribution to package manager
case "$dist_id" in
  ubuntu|debian)
    pkg_mgr="apt"
    ;;
  fedora|rhel|centos|rocky|alma|ol)  # Fedora, RHEL, CentOS, Rocky, AlmaLinux, Oracle
    pkg_mgr="dnf"  # Use dnf (alias to yum on newer RHEL/Fedora):contentReference[oaicite:3]{index=3}.
    ;;
  arch|manjaro|endeavouros|steam|arcolinux)
    pkg_mgr="pacman"
    ;;
  suse|opensuse|sles)
    pkg_mgr="zypper"
    ;;
  alpine)
    pkg_mgr="apk"
    ;;
  gentoo)
    pkg_mgr="emerge"
    ;;
esac

print_box "Detected OS: $PRETTY_NAME (Package manager: $pkg_mgr)"

# Install required dependencies: curl, Node.js, npm
case "$pkg_mgr" in
  apt)
    # Update package index and install curl
    sudo apt-get update -y && sudo apt-get install -y curl ca-certificates
    # Use NodeSource to get a recent Node.js LTS for Debian/Ubuntu:contentReference[oaicite:4]{index=4}.
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || {
      echo "NodeSource setup script failed. Installing nodejs from apt..."
    }
    sudo apt-get install -y nodejs npm build-essential
    ;;
  dnf)
    sudo dnf install -y curl ca-certificates gcc-c++ make
    # Add NodeSource repository for Node.js 18 on RHEL/Fedora:contentReference[oaicite:5]{index=5}.
    curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash - || {
      echo "NodeSource repo not added. Trying default packages."
    }
    sudo dnf install -y nodejs npm
    ;;
  pacman)
    sudo pacman -Sy --noconfirm curl nodejs npm  # Arch Linux / Manjaro:contentReference[oaicite:6]{index=6}
    ;;
  zypper)
    sudo zypper --non-interactive install curl ca-certificates
    # Install latest LTS Node.js (openSUSE provides multiple versions):contentReference[oaicite:7]{index=7}.
    # Try Node.js 18 first, fallback to default if not found.
    if ! sudo zypper --non-interactive install nodejs18 npm18 2>/dev/null; then
      sudo zypper --non-interactive install nodejs npm || sudo zypper --non-interactive install nodejs14 npm14
    fi
    ;;
  apk)
    sudo apk add --no-cache curl nodejs npm
    ;;
  emerge)
    print_box "Gentoo detected. Please ensure Node.js and npm are installed manually."
    ;;
  *)
    print_box "Unsupported or unknown package manager. Please install Node.js (>=18), npm, and curl, then re-run this script."
    exit 1
    ;;
esac

# Verify Node.js and npm installation
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is not installed. Aborting."
  exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
  echo "npm is not installed. Aborting."
  exit 1
fi

# Install Nativefier globally via npm:contentReference[oaicite:8]{index=8}
if ! command -v nativefier >/dev/null 2>&1; then
  print_box "Installing Nativefier (via npm)..."
  sudo npm install -g nativefier:contentReference[oaicite:9]{index=9}
fi

# Prepare Nativefier to create WhatsApp desktop app
APP_NAME="WhatsApp"
WHATSAPP_URL="https://web.whatsapp.com"
INSTALL_DIR="${HOME}/.local/share/nativefier"
APP_OUTPUT_DIR="${INSTALL_DIR}/${APP_NAME}-linux-$(uname -m)"

# Ensure target directories exist and are owned by the invoking user
USER_NAME="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
mkdir -p "$USER_HOME/.local/share/nativefier" "$USER_HOME/.local/share/applications" "$USER_HOME/.config/autostart"
sudo chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/.local/share/nativefier" "$USER_HOME/.local/share/applications" "$USER_HOME/.config/autostart"

print_box "Generating WhatsApp desktop application with Nativefier..."
# Use Nativefier to create the app (single-instance, start in tray):contentReference[oaicite:10]{index=10}:contentReference[oaicite:11]{index=11}.
# Run as the normal user to avoid root-owned output
sudo -u "$USER_NAME" nativefier --name "$APP_NAME" --single-instance --tray "$WHATSAPP_URL" "$INSTALL_DIR"

# Find the generated app directory and binary
if [[ -d "$APP_OUTPUT_DIR" ]]; then
  APP_DIR="$APP_OUTPUT_DIR"
else
  # If architecture suffix differs (e.g., arm64)
  APP_DIR=$(find "$INSTALL_DIR" -maxdepth 1 -type d -name "${APP_NAME}-linux-*")
fi
APP_BIN="$APP_DIR/${APP_NAME// /}"  # Binary name is app name without spaces

# Create desktop entry for the application
DESKTOP_FILE="$USER_HOME/.local/share/applications/${APP_NAME// /}.desktop"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=WhatsApp Web
Exec=${APP_BIN}
Icon=${APP_DIR}/resources/app/icon.png
Comment=WhatsApp Web Desktop (Nativefier)
Categories=Network;Chat;
StartupWMClass=WhatsApp
EOF

# Set up autostart on login (copy .desktop to autostart with autostart enabled key):contentReference[oaicite:12]{index=12}
AUTOSTART_FILE="$USER_HOME/.config/autostart/${APP_NAME// /}.desktop"
cp "$DESKTOP_FILE" "$AUTOSTART_FILE"
if ! grep -q "X-GNOME-Autostart-enabled" "$AUTOSTART_FILE"; then
  echo "X-GNOME-Autostart-enabled=true" >> "$AUTOSTART_FILE"
fi

sudo chown "$USER_NAME":"$USER_NAME" "$DESKTOP_FILE" "$AUTOSTART_FILE"

print_box "Installation complete! WhatsApp Web has been installed as a desktop app."
echo "Launcher: $DESKTOP_FILE"
echo "Autostart entry: $AUTOSTART_FILE (app will auto-launch minimized to tray on login)"

# Headless (server) mode option
if [[ -z "$DISPLAY" ]]; then
  echo -e "\n\033[1;33mNOTE:\033[0m No graphical display detected (headless environment):contentReference[oaicite:13]{index=13}."
  echo "WhatsApp Web requires a GUI environment to run:contentReference[oaicite:14]{index=14}."
  read -rp "Install Xvfb and run WhatsApp Web in headless mode (Y/N)? " REPLY
  if [[ "$REPLY" =~ ^[Yy] ]]; then
    # Install Xvfb (virtual X server):contentReference[oaicite:15]{index=15} for the detected package manager
    case "$pkg_mgr" in
      apt) sudo apt-get install -y xvfb ;;
      dnf) sudo dnf install -y xorg-x11-server-Xvfb ;;
      pacman) sudo pacman -Sy --noconfirm xorg-server-xvfb ;;
      zypper) sudo zypper --non-interactive install xorg-x11-server ;;
      apk) sudo apk add --no-cache xvfb ;;
    esac
    # Create a systemd service for headless autostart if systemd is available
    if command -v systemctl >/dev/null 2>&1; then
      SERVICE_FILE="/etc/systemd/system/whatsapp-web-headless.service"
      sudo bash -c "cat > $SERVICE_FILE" <<EOM
[Unit]
Description=WhatsApp Web (Nativefier) Headless Service
After=network.target

[Service]
Type=simple
User=$USER_NAME
Environment=DISPLAY=:99
ExecStart=/usr/bin/xvfb-run -a -s "-screen 0 1280x720x24" "${APP_BIN}"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOM
      sudo systemctl enable whatsapp-web-headless.service
      print_box "Headless mode enabled: 'whatsapp-web-headless' service installed."
      echo "WhatsApp Web will run in a virtual display (Xvfb) on boot:contentReference[oaicite:16]{index=16}."
    else
      print_box "Systemd not detected. You can run WhatsApp headlessly with Xvfb as needed:"
      echo "Example: xvfb-run -a -s \"-screen 0 1280x720x24\" \"${APP_BIN}\""
    fi
    echo -e "\033[1;33mImportant:\033[0m To use WhatsApp Web headlessly, you must first log in by scanning the QR code at least once on a system with a GUI:contentReference[oaicite:17]{index=17}."
    echo "Consider running the app with a GUI or forwarding X display for the initial login (save the session after QR scan):contentReference[oaicite:18]{index=18}."
  fi
fi

