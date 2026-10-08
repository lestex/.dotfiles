-- App hotkeys (Hammerspoon). Installed from the dotfiles repo
-- (.config/hammerspoon); edit it there and re-run ./install.sh hotkeys.
--
--   Cmd+Ctrl+T   the terminal
--   Cmd+Ctrl+B   the browser
--
-- Each opens the app, or brings it to the front if it is already running.
-- Cmd+Ctrl, because Cmd+T (new tab) and Cmd+B (bold) belong to the apps.
--
-- The terminal is chosen with `terminal-switcher ghostty|alacritty|kitty`,
-- read on every press. Other apps go in ~/.config/hammerspoon/local.lua,
-- which the installer never touches, e.g.:
--
--   return { browser = "Safari" }
--
-- Saving any file here reloads the config.

local apps = {
  terminal = "Ghostty",
  browser = "Google Chrome",
}

local localFile = hs.configdir .. "/local.lua"
if hs.fs.attributes(localFile) then
  local ok, overrides = pcall(dofile, localFile)
  if ok and type(overrides) == "table" then
    for name, app in pairs(overrides) do
      apps[name] = app
    end
  else
    hs.alert.show("local.lua: " .. tostring(ok and "must return a table" or overrides), 5)
  end
end

-- terminal-switcher's choice, by its lowercase name; local.lua's terminal
-- (or Ghostty) when there is none.
local terminalApps = { ghostty = "Ghostty", alacritty = "Alacritty", kitty = "kitty" }
local terminalChoice = os.getenv("HOME") .. "/.local/state/terminal-switcher/current"

local function appFor(name)
  if name == "terminal" then
    local f = io.open(terminalChoice)
    if f then
      local choice = (f:read("*l") or ""):match("^%s*(.-)%s*$")
      f:close()
      if terminalApps[choice] then
        return terminalApps[choice]
      end
    end
  end
  return apps[name]
end

local function open(name)
  return function()
    local app = appFor(name)
    if not hs.application.launchOrFocus(app) then
      hs.alert.show("Can't open " .. tostring(app) .. " (" .. name .. ")", 3)
    end
  end
end

hs.hotkey.bind({ "cmd", "ctrl" }, "t", open("terminal"))
hs.hotkey.bind({ "cmd", "ctrl" }, "b", open("browser"))

-- Hammerspoon's own windows (Preferences, Console) are light unless told
-- otherwise: follow macOS's Dark/Light, which theme-switcher sets per theme.
local function followAppearance()
  local dark = hs.host.interfaceStyle() == "Dark"
  hs.preferencesDarkMode(dark)
  hs.console.darkMode(dark)
end
followAppearance()
AppearanceWatcher = hs.distributednotifications.new(function()
  hs.timer.doAfter(0.5, followAppearance)
end, "AppleInterfaceThemeChangedNotification"):start()

-- Reload when a .lua file here changes. Kept in a global, or it is
-- garbage-collected and stops watching.
ConfigWatcher = hs.pathwatcher.new(hs.configdir, function(files)
  for _, file in ipairs(files) do
    if file:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end):start()

hs.autoLaunch(true)
