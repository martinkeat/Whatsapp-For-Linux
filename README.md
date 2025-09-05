# WhatsApp-For-Linux

**WhatsApp-For-Linux** is an unofficial installer and wrapper that brings [WhatsApp Web](https://web.whatsapp.com) to the Linux desktop as a native application. It uses [Nativefier](https://github.com/nativefier/nativefier) (Electron) to package WhatsApp Web into a desktop app that runs on all major Linux distributions.  

This project is developed and maintained by **spontaneocus (Martin J. Keatings)** and is **not affiliated with or endorsed by WhatsApp Inc.**. In short, it provides the convenience of a dedicated WhatsApp desktop client for Linux, without needing to keep a browser open.

---

## 🚀 Features and Compatibility

- **Native Desktop Experience:** Runs as a standalone application with its own window and icon – no web browser needed.  
- **Full WhatsApp Web Functionality:** Access chats, groups, voice messages, file sharing, and Status updates (note: *voice/video calls are not supported* as they are not part of WhatsApp Web).  
- **Desktop Notifications:** Get real-time notifications through your system’s notification service.  
- **System Integration:** Adds a desktop launcher (.desktop file) and supports autostart at login.  
- **Cross-Distribution Support:** Works with Debian/Ubuntu, Fedora/RHEL, Arch/Manjaro, openSUSE, Alpine, Gentoo, and more.  
- **Always Up to Date:** Uses the live WhatsApp Web, so the interface updates automatically as WhatsApp updates their web app.  
- **Headless/Server Mode:** Can run on servers without displays using [Xvfb](https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml).  

---

## 🖥️ What is Nativefier?

[Nativefier](https://github.com/nativefier/nativefier) is a command-line tool that turns any website into a desktop application using [Electron](https://www.electronjs.org/).  

Why use this instead of just a browser shortcut?

- **Dedicated App Window:** No address bar, no browser clutter – just WhatsApp.  
- **Persistent Login:** Keeps your QR-code login session even if you clear your browser cache.  
- **Desktop Integration:** Appears in your application menu, has its own icon, and uses native notifications.  
- **Controlled Updates:** The Electron engine can be updated independently of your system browser.  

In short: it feels like a native app while being just WhatsApp Web under the hood.

---

## 📥 Installation

Run the following one-liner for your distribution. Replace `<user>/<repo>` with this repository path:  
`martinkeat/Whatsapp-For-Linux`

### Debian / Ubuntu / Raspberry Pi OS / Linux Mint
```bash
curl -fsSL https://raw.githubusercontent.com/martinkeat/Whatsapp-For-Linux/main/install-debian.sh | bash
