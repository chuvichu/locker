# Windows Hosts Locker

A lightweight, background anti-tamper locking mechanism for Windows that makes it impossible to cut, move, rename, delete, or overwrite the system `hosts` file (`C:\Windows\System32\drivers\etc\hosts`) from File Explorer or standard scripts.

---

## 🔒 How It Works

Windows file system semantics enforce strict handle sharing rules:
- When a file is opened with `FileAccess.Read` and `FileShare.Read`, the caller requests read access while permitting other processes (such as Windows DNS Resolver, web browsers, and network services) to read the file concurrently.
- By omitting `FileShare.Delete` and `FileShare.Write`, the Windows kernel strictly rejects any operation that attempts to:
  - **Move / Cut** the file out of `C:\Windows\System32\drivers\etc`
  - **Delete** the file or send it to Recycle Bin
  - **Rename** the file
  - **Overwrite** or replace the file

Whenever someone attempts any of the above operations in File Explorer or Command Prompt, Windows halts the operation with:
> *"The action can't be completed because the file is open in another program."*

---

## 🚀 Quick Start

### 1. Installation (Run as Administrator)

Open **PowerShell as Administrator** in the project folder and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\install.ps1
```

**What the installer does:**
1. Copies `LockHosts.ps1` to `%ProgramData%\HostsLocker\`.
2. Registers a hidden scheduled background task (`WindowsHostsLocker`) under the `SYSTEM` account.
3. Configures the task to automatically start on boot and restart if terminated.
4. Starts the lock handle immediately.

---

### 2. Verify the Lock

Run the status check script in PowerShell:

```powershell
.\status.ps1
```

You should see:
```text
[+] Scheduled Task: INSTALLED (State: Running)
[+] Active Locking Process: RUNNING
[+] Lock Test: SUCCESS (File is actively locked by Windows kernel!)
```

Now try opening File Explorer, navigating to `C:\Windows\System32\drivers\etc`, and pressing **Delete** or **Cut** on `hosts`. Windows will block the action.

---

### 3. Uninstallation (When you legitimately need to edit)

To release the lock and remove the background task:

```powershell
.\uninstall.ps1
```

---

## 📁 Repository Structure

```text
├── LockHosts.ps1    # Core locking script (holds exclusive FileShare.Read handle)
├── install.ps1      # Automatic installer (SYSTEM Scheduled Task)
├── uninstall.ps1    # Safe uninstaller and process cleanup
├── status.ps1       # Health and lock verification script
├── LICENSE          # MIT License
└── README.md        # Documentation
```

---

## ⚠️ Technical Limitations & Security Realities

1. **Administrator Access:** Any user with full Administrator privileges can stop the scheduled task or terminate the process. For true self-restriction (e.g. anti-distraction / productivity), consider using a daily **Standard User** account and securing the Administrator password with a delayed release tool (like [Lockbox](https://lockbox.page/)).
2. **DNS over HTTPS (DoH):** Modern browsers (Chrome, Edge, Firefox) can bypass the local `hosts` file if "Secure DNS" (DNS over HTTPS) is enabled in browser settings. Disable DoH in your browser if you rely on `hosts`-based blocking.

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
