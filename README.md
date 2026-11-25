# Odablock Sounds RS3

Download the [beta install ZIP](https://github.com/DapperMickie/odablock-sounds-rs3/releases/tag/v0.8.0) and extract its contents into the beta client's `dev_plugins/odablock-sounds-rs3` directory. The ZIP includes the sounds, emote images, and emote catalog. The client loads them from the installed package on startup.


This RS3 beta port of [Odablock Sounds](https://github.com/DapperMickie/odablock-sounds) uses converted clips from the local RuneLite sound pack. It recognizes English game messages and handles reconnect transitions.

In the beta client, run:

```text
prf
ppe odablock-sounds-rs3 chatAccess
pon odablock-sounds-rs3
```

Use `prf` followed by `prl odablock-sounds-rs3` after adding or renaming clips.

Press Ctrl+Alt+F7 to open the settings window. With [PrettyUI](https://prettyui.j3.gg/) available, the window has three tabs, and the Plugin Hub gear opens the same tabs:

- **Sounds** groups every clip into Progress, Loot and pets, Combat, Trading and reports, World and NPCs, Session, and Extras and stream. Each sound with an RS3 trigger has its own checkbox and a **Play** button. Each group has **Enable all** and **Disable all**. Sounds without an RS3 trigger are labelled *preview only* and have a Play button but no checkbox. The section at the top selects a sound for **Preview**, **Stop**, and **Change clip**. **Change clip** switches between a random variant and each variant in turn.
- **Emotes** turns overhead and inline emotes on or off. It also lists all 20 emotes with their image, triggers, a checkbox, and a **Preview** button.
- **Settings** contains volume, captions, the music player, alert feed checks, the menu shortcut, Developer mode, and the test hotkeys. The menu shortcut accepts one or two keys. **Reset to Ctrl+Alt+F7** restores the original binding.

The window saves every setting and reopens on the last tab used. Every emote stays enabled when you upgrade from an earlier version.

In the beta client, the local copy of PrettyUI can be enabled with `pon prettyui-local` after `prf`. Then reload Odablock Sounds. If PrettyUI is absent or fails to build the window, the original panel opens. Its arrow buttons select a sound or an emote. Click a sound name to preview it, and click an emote name to turn that emote on or off.

Ctrl+Alt+F8, F9, and F10 test sample messages for level-up, quest completion, and collection log. Add Shift for direct playback. Ctrl+Shift+F9 also previews the level-up clip.

Skill updates and local level-up messages can trigger the same sound. The plugin suppresses duplicate cues for the same skill and level and ignores temporary buffs and drains on the skill-event path. Additional game-message patterns include milestones, Area Tasks, Combat Mastery, pet unlocks, death, PvP kills, selected combat effects, trades, and NPC interactions. These additional patterns still need live RS3 examples for validation.

Rare-drop and skilling-pet broadcasts play their clips when the message names your character as the recipient. The sound triggers ignore public player chat and broadcasts naming other players. Enable Valuable ground drop under Sounds to hear rare-drop audio when an owned ground item meets your minimum GP value. Set the exact amount under Settings. The cue requires HTTP Access to fetch GE guide prices. Selected boss-unique broadcasts use the separate boss-unique clip. Empty Barrows chests, Dharok axe styles, and bank opening are available for preview. Custom Barrows faces and settings import/export are pending.

### Alerts and music

Enable **Livestream alert** and **Plugin announcement** under **Sounds → Extras and stream**. These are opt-in and read the same public feeds as the OSRS plugin about once per minute while logged in. They require optional `httpAccess`. The first successful check establishes the current state, so an old announcement or a stream already in progress does not play an alert sound. Use **Settings → Check feeds** to verify the connection.

Play **Terry** and **Odablock Warriors** from **Settings → Music**. Both tracks use the RS3 music volume and have their own stop control. Gameplay cues can play while a track continues.

### Build the release

The repository includes the Ogg sounds in `resources/`, PNG emotes in `resources/emotes/`, and chat tokens in `emote_catalog.lua`. Run `python tools/build_odablock_release.py` from the source checkout to build the install ZIP in `dist/`. The build uses the checked-in assets and omits the local debug listener URL and local PrettyUI alias from the packaged manifest.

### Emotes

Enable **Show emotes above speakers** on the Emotes tab to show the Odablock emotes above visible speakers when a trigger appears in public, friends, clan, or group chat. Try `kek`, `odawhat`, or `:)`. **Preview next emote** and each emote's **Preview** button show an image above your own character without sending a chat message. RS3 draws the images in a separate overlay and leaves the original chat text readable.

Clear an emote's checkbox to hide it above speakers and in inline chat. This covers all of its triggers, such as both `:)` and `smile`. Inline chat rows that are already visible return to plain text for that emote. Previews still work for disabled emotes.

The experimental **Inline emotes in All Chat** setting uses the native desktop chat rows. Enable it and select **Test inline emotes** to add a local-only test line. The renderer also checks existing chat history on load. Short, single-line messages can use inline sprites. Wrapped messages and layouts without the expected chat components keep their original text. Public overhead emote badges last approximately 3.5 seconds.

The rat sound can play without a chat message. The plugin tracks the rat selected with Attack and infers a kill when that NPC disappears close to a combat XP gain. This can miss kills without a recent Attack selection or XP update, and nearby combat events can occasionally coincide.

To use your own clips, replace the corresponding file in the installed `resources` folder with Ogg Vorbis audio. The preview result shows the resource filename.

The settings panel includes all 85 convertible clips from the local RuneLite pack. OSRS-specific and extra clips appear as preview-only entries when they have no RS3 trigger. The local `Seryna.wav` contains a 404 response and has no audio.

### Developer mode

Enable **Developer mode** on the Settings tab to capture numeric player-variable changes and local game messages. Traces appear in the beta console. With the optional HTTP permission granted, the plugin also sends those traces to a listener bound to this computer's loopback interface.

Run `prf`, `ppe odablock-sounds-rs3 httpAccess`, and `prl odablock-sounds-rs3` in the beta console. The local listener is `python tools/odablock_debug_listener.py odablock-debug.log`. Turn Developer mode off when the test is done.

