# WhatsApp-For-Linux

**WhatsApp-For-Linux** is an unofficial installer and wrapper that brings WhatsApp Web (https://web.whatsapp.com) to the Linux desktop as a native application. It uses Nativefier (https://github.com/nativefier/nativefier) (Electron) to package WhatsApp Web into a desktop app that runs on all major Linux distributions.  

This project is developed and maintained by spontaneocus (Martin J. Keatings) and is not affiliated with or endorsed by WhatsApp Inc. In short, it provides the convenience of a dedicated WhatsApp desktop client for Linux, without needing to keep a browser open.

---

## 🚀 Features and Compatibility

- Native Desktop Experience: Runs as a standalone application with its own window and icon – no web browser needed.  
- Full WhatsApp Web Functionality: Access chats, groups, voice messages, file sharing, and Status updates (note: voice/video calls are not supported as they are not part of WhatsApp Web).  
- Desktop Notifications: Get real-time notifications through your system’s notification service.  
- System Integration: Adds a desktop launcher (.desktop file) and supports autostart at login.  
- Cross-Distribution Support: Works with Debian/Ubuntu, Fedora/RHEL, Arch/Manjaro, openSUSE, Alpine, Gentoo, and more.  
- Always Up to Date: Uses the live WhatsApp Web, so the interface updates automatically as WhatsApp updates their web app.  
- Headless/Server Mode: Can run on servers without displays using Xvfb (https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml).  

---

## 🖥️ What is Nativefier?

Nativefier (https://github.com/nativefier/nativefier) is a command-line tool that turns any website into a desktop application using Electron (https://www.electronjs.org/).  

Why use this instead of just a browser shortcut?

- Dedicated App Window: No address bar, no browser clutter – just WhatsApp.  
- Persistent Login: Keeps your QR-code login session even if you clear your browser cache.  
- Desktop Integration: Appears in your application menu, has its own icon, and uses native notifications.  
- Controlled Updates: The Electron engine can be updated independently of your system browser.  

In short: it feels like a native app while being just WhatsApp Web under the hood.

---

## 📥 Installation

## Run the following one-liner for your distribution.


### Debian / Ubuntu / Raspberry Pi OS / Linux Mint:
```
curl -fsSL https://raw.githubusercontent.com/martinkeat/Whatsapp-For-Linux/main/install-debian.sh | bash
```

### Fedora / RHEL / CentOS / Rocky / AlmaLinux:
```
curl -fsSL https://raw.githubusercontent.com/martinkeat/Whatsapp-For-Linux/main/install-fedora.sh | bash
```

### Arch / Manjaro / EndeavourOS:
```
curl -fsSL https://raw.githubusercontent.com/martinkeat/Whatsapp-For-Linux/main/install-arch.sh | bash
```

### openSUSE / SUSE Linux Enterprise:
```
curl -fsSL https://raw.githubusercontent.com/martinkeat/Whatsapp-For-Linux/main/install-opensuse.sh | bash
```

### Alpine Linux:
```
curl -fsSL https://raw.githubusercontent.com/martinkeat/Whatsapp-For-Linux/main/install-alpine.sh | bash
```

### Gentoo Linux:
```
curl -fsSL https://raw.githubusercontent.com/martinkeat/Whatsapp-For-Linux/main/install-gentoo.sh | bash
```

### After install, look for WhatsApp in your app menu. First run requires scanning the QR code with your phone.

---

## 🖧 Headless Server Usage

You can run WhatsApp-For-Linux without a GUI using Xvfb (X virtual framebuffer).  

Example with xvfb-run:
xvfb-run -a whatsapp-for-linux

Or create a systemd service at /etc/systemd/system/whatsapp.service:
```
[Unit]
Description=WhatsApp for Linux (headless)
After=network.target

[Service]
Type=simple
User=yourusername
Environment=DISPLAY=:99
ExecStart=/usr/bin/xvfb-run -a /usr/bin/whatsapp-for-linux
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
Note: You must perform the initial QR code login in a GUI environment (or by viewing the Xvfb display with VNC/screenshot) before running headless.

---

## 📦 Offline Installation

For systems without internet:

1. Download Node.js + npm packages for your distro (https://nodejs.org/en/download/).  
2. Download the Nativefier npm package (npm pack nativefier).  
3. Transfer them to the offline machine.  
4. Run:
   npm install -g ./nativefier-<version>.tgz
   nativefier --name "WhatsApp" https://web.whatsapp.com
5. Place the output app in /opt/WhatsApp and create a .desktop file manually.

---

## 🛠️ Troubleshooting

- App won’t launch:  
  whatsapp-for-linux --no-sandbox  

- “Update Browser” message:  
  Update Nativefier/Electron: npm install -g nativefier  

- No notifications:  
  Enable in WhatsApp Settings → Notifications. Ensure a notification daemon is running.  

- Tray icon missing:  
  GNOME hides tray icons; install an extension like AppIndicator Support.  

- Autostart not working:  
  Ensure the .desktop file exists in ~/.config/autostart/ and contains X-GNOME-Autostart-enabled=true.  

- Logs:  
  Run whatsapp-for-linux in a terminal to view console logs.  

---

## ❌ Uninstallation

1. Remove the app files (adjust path if different):
   sudo rm -rf /opt/WhatsApp

2. Remove desktop shortcut:
   rm ~/.local/share/applications/WhatsApp.desktop

3. Remove autostart entry:
   rm ~/.config/autostart/WhatsApp.desktop

4. (Optional) Remove config data:
   rm -rf ~/.config/whatsapp*

---

## 📚 Dependencies & Attribution

- WhatsApp Web – © WhatsApp Inc. (Meta Platforms)  
- Nativefier – © Jia Hao, MIT License  
- Electron – © OpenJS Foundation / GitHub, MIT License  
- Node.js – © OpenJS Foundation, MIT License  
- npm – © npm Inc. / GitHub, Artistic License 2.0  
- Xvfb – © X.Org Foundation, MIT License  

---

## 🤝 Contributing & Support

- Open an Issue: https://github.com/martinkeat/Whatsapp-For-Linux/issues  
- Fork the repo and submit a Pull Request for improvements.  

---

## 📜 License

This project is released under the MIT License.  
See LICENSE for full details.  

---

## ☕ Support Development

Maintained by spontaneocus (Martin J. Keatings).  
If you find this project useful, consider buying me a coffee:

Donate via PayPal: https://paypal.me/spontaneocus
