<p align="center">
  <a href="https://discord.gg/simplelootcouncil"><img src="https://raw.githubusercontent.com/SimpleLootCouncil/media/main/addon-page/button-discord.png" alt="Discord"></a>
  <a href="https://ko-fi.com/laxxz"><img src="https://raw.githubusercontent.com/SimpleLootCouncil/media/main/addon-page/button-kofi.png" alt="Ko-fi"></a>
  <a href="https://github.com/Laxxzz/EnvironmentPing/issues"><img src="https://raw.githubusercontent.com/SimpleLootCouncil/media/main/addon-page/button-issue.png" alt="Report an issue"></a>
</p>

**EnvironmentPing** is a ping wheel for **Retail**. Hold a key, left-click where you want the ping, flick toward an icon and release. Its pings land on the world, never on a unit or an interface frame, whatever your Ping Target setting says.

## Features

- Environment-only pings, no Ping Target toggling
- Six ping types on the wheel
- Drag to reorder the wheel
- Release without flicking for a plain ping
- Instant ping mode, no wheel
- Adjustable dead zone and wheel size
- Bind the key in Key Bindings or the addon's options

## Getting Started

Requires WoW 12.1.0 or later. Download the latest zip from [Releases](https://github.com/Laxxzz/EnvironmentPing/releases) and extract it into `World of Warcraft\_retail_\Interface\AddOns`, then `/reload`. Bind **Ping Wheel** under Key Bindings > EnvironmentPing, or set the key in the addon's options.

Hold the key, left-click where you want the ping, flick toward an icon and release. Open the options with `/ep` (or `/eping`). While the key is held, left-click belongs to the wheel and the camera will not rotate.

## Why it exists

12.1.0 added a Ping Target setting and a keybind to toggle it, but toggling is modal: you are either pinging units or you are not. EnvironmentPing makes it per-ping instead. Nothing is toggled and no setting is written, so there is nothing to restore if you change your mind halfway through a gesture.

## Options

| Option | What it does |
|---|---|
| Ping wheel key | Sets the real keybind, so it also shows up in Blizzard's Key Bindings panel |
| Enabled | Turns the wheel off without unbinding its key |
| Environment only | Off sends ordinary pings that obey your Ping Target setting |
| Instant ping (no wheel) | Hold the key and the mouse-down itself sends a plain ping under the cursor |
| Click without moving pings | Off makes a no-flick release cancel instead |
| Dead zone | How far you must flick before an icon is chosen, which is also how far the ping can miss by |
| Wheel radius | Appearance only; an icon is chosen by direction, not distance |
| Pings on the wheel | Which of the six ping types appear, and in what order |

## How it works

The ping is `/ping [@cursor] N` run from a secure button's macro. The `@cursor` token makes Blizzard's `SendMacroPing` pass through all UI, ignore units and ignore the Ping Target setting. Types are addressed by number because the slash handler's name keys are localised, so `/ping attack` would silently degrade to an untyped ping on non-English clients.

The mouse button that opens the wheel is claimed from inside a secure snippet for as long as the key is held, and the icon a release fires is decided there too, so it keeps working once you are in combat.

The ping lands where the cursor is at release, not where you clicked, because Blizzard's hit-test ping functions are secure-only. The dead zone is therefore the accuracy budget, which is why it is small, visible while the wheel is open, and adjustable.

## AI Use

Claude was used in the development of this addon with a custom-built addon development tool constructed from Blizzard's API patch notes.

## Support

EnvironmentPing is free. If it saves you fiddling with Ping Target mid-pull, you can support its development.

<p align="center"><a href="https://ko-fi.com/laxxz"><img src="https://raw.githubusercontent.com/SimpleLootCouncil/media/main/addon-page/button-kofi.png" alt="Support Laxx on Ko-fi"></a></p>

## Licence

MIT. See [LICENSE](LICENSE).
