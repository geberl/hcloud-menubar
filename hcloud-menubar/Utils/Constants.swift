import Foundation
import SwiftUI

// MARK: - AppSettings Keys

let AppSettingsTerminal: String = "appTerminal"
let AppSettingsEditor: String = "appEditor"
let AppSettingsTimeout: String = "timeoutSeconds"

// MARK: - Token Configuration

let PermissionReadOnly: Int = 0
let PermissionReadWrite: Int = 1

let PermissionsValues: [Int: String] = [
    PermissionReadOnly: "Read-Only",
    PermissionReadWrite: "Read-Write",
]

// MARK: - Settings Window Dimensions

/// Width of the settings window. The TabView and the full-width Projects tab share it.
let SettingsWindowWidth: CGFloat = 625
let SettingsProjectsHeight: CGFloat = 535
let SettingsProjectsSidebarWidth: CGFloat = 200
let SettingsProjectDetailWidth: CGFloat = 425
let SettingsGeneralWidth: CGFloat = 480
let SettingsLabelsWidth: CGFloat = 450
let SettingsDebugWidth: CGFloat = 450
let SettingsAboutWidth: CGFloat = 450

// MARK: - Label Configuration

let LabelBoolsPositive: [String] = ["yes", "Yes", "YES", "true", "True", "TRUE", "1"]

// MARK: - Application Bundle Identifiers

/// Finding out bundle identifiers: `codesign -dr - /Applications/kitty.app` (only works if signed)
/// Otherwise look at Info.plist inside the app, key `CFBundleIdentifier`
let TerminalDefault: String = "com.apple.Terminal"
let TerminalValuesOpenUrl: [String: String] = [
    "Terminal": "com.apple.Terminal",
    "iTerm2": "com.googlecode.iterm2",
    "Kitty": "net.kovidgoyal.kitty",
]
let TerminalValuesOpenCommand: [String: String] = [
    "Ghostty": "com.mitchellh.ghostty",
    "Hyper": "co.zeit.hyper",
    "WezTerm": "com.github.wez.wezterm",
    "Warp": "dev.warp.Warp-Stable",
]
let TerminalValues: [String: String] =
    TerminalValuesOpenUrl.merging(TerminalValuesOpenCommand) { _, new in new }

let EditorDefault: String = "com.apple.TextEdit"
let EditorValues: [String: String] = [
    "TextEdit": "com.apple.TextEdit",
    "VSCode": "com.microsoft.VSCode",
    "Sublime Text": "com.sublimetext.4",
    "MacVim": "org.vim.MacVim",
    "VimR": "com.qvacua.VimR",
    "Xcode": "com.apple.dt.Xcode",
    "BBEdit": "com.barebones.bbedit",
    "VSCodium": "com.vscodium",
    "CotEditor": "com.coteditor.CotEditor",
    "Nova": "com.panic.Nova",
]

// MARK: - API Configuration

let DefaultApiBaseUrl: String = "https://api.hetzner.cloud/v1"
let DefaultHetznerConsoleBaseUrl: String = "https://console.hetzner.cloud"
let TimeoutDefault: Double = 5

/// Items requested per page when listing a resource. Hetzner's default is 25 and the max is 50.
let ResourcesPerPage: Int = 50
/// Defensive upper bound on how many pages a single list load will follow before stopping.
/// At `ResourcesPerPage` items each this caps a load at 1000 items; hitting it is logged.
let ResourcesMaxPages: Int = 20

// MARK: - SSH Configuration

let DefaultSSHUser: String = "root"
let DefaultSSHPort: String = "22"

/// How long the temporary `ssh-<UUID>.command` file is kept after launching the terminal before
/// it is deleted. Long enough for the terminal to read and execute it, short enough that the
/// files don't linger.
let SshCommandFileLifetimeSeconds: Int = 10

// MARK: Label Configuration

let labelHide: String = "hcloud-menubar/hide"
let labelSSHHost: String = "hcloud-menubar/ssh-host"
let labelSSHUser: String = "hcloud-menubar/ssh-user"
let labelSSHPort: String = "hcloud-menubar/ssh-port"
let labelSSHDisable: String = "hcloud-menubar/ssh-disable"

// MARK: Colors

extension Color {
    static let hcloudRed = Color(hex: "D50B2D")
}
