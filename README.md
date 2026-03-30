# Event Tracker

A plugin for Roblox studio for you to easily track and manage event instances in your roblox game.

### Official Plugin: [Event Tracker - Roblox Creator Store](https://create.roblox.com/store/asset/100479477788872/Event-Tracker)

---

## Features
- Monitor all RemoteEvents, UnreliableRemoteEvents, and BindableEvents in your game  
- Inspect event fires and listeners
- Inspect script connections and line references for each event
- See unused events
- Search events

---

## Usage
1. Open Event Tracker from the Plugins tab  
3. Use the search bar to find a specific event
4. Click select to select the instance in the roblox studio explorer
5. Click Code to open a see all script references with line numbers  
6. Click Delete to remove an event
7. Use Refresh to search for events again
8. If any events are unused (if they're never fired or listened to), the Clean Up button will be visible. Click it and you'll see a list of all unused events.

---

## How It Works
The plugin uses a code scanning algorithm:  
- Analyzes all scripts in your game
- Detects where events are fired (FireServer, FireClient, Fire)
- Detects where events are listened to (OnServerEvent, OnClientEvent, Event)
- Gets code line references

---

## License
Code is released under the MIT License
Free to use, modify, and distribute.
Please see the 'LICENSE' file for full details

---

Happy building! :)