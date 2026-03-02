# Event Tracker ⚡️
**By Fox Jet Studios**

Track, manage, and explore all **RemoteEvents** and **BindableEvents** in your Roblox game with zero hassle. Powered by a **smart algorithm** that scans scripts to locate event listeners and firers.

### Official Plugin: [Event Tracker - Roblox Creator Store](https://create.roblox.com/store/asset/100479477788872/Event-Tracker)

---

## Features ✨
- ✅ Monitor **all RemoteEvents, UnreliableRemoteEvents, and BindableEvents** in your game  
- ✅ Powerful algorithm that analyzes your scripts to find where events are fired and listened to  
- ✅ Quickly view **event triggers and listeners**  
- ✅ Inspect **script connections** and line references for each event  
- ✅ Delete events safely using a **confirmation modal**  
- ✅ Search and filter events in real time
- ✅ Lightweight, modern, and user-friendly interface

---

## Usage 🚀
1. Open **Event Tracker** from the Plugins tab  
2. The main window lists all tracked events in your game  
3. Use the **search bar** to filter events by name or path  
4. Click **Select** to highlight an event in Explorer  
5. Click **Code** to open a window showing **all script references** with line numbers  
6. Click **Delete** to remove an event with a confirmation modal  
7. Use **Refresh** to rescan all events and update the list  
8. If any events are unused (never fired or listened to), use the **Clean Up** feature to delete them quickly  

---

## How It Works ⚡
The plugin uses a **complex scanning algorithm**:  
- Analyzes all scripts in your game  
- Detects where events are fired (`FireServer`, `FireClient`, `Fire`)  
- Detects where events are listened to (`OnServerEvent`, `OnClientEvent`, `Event`)  
- Collects line references and previews so you can jump straight to the code
- No matter if you defined the event instance or if you just used something like game.ReplicatedStorage.Events.CoolEvent.

**Demonstration video:**

https://github.com/user-attachments/assets/46fad58e-f917-489f-afb3-0e7fd6d2700b

---

## License 📜
Released under the **MIT License**: free to **use, modify, and distribute**. Please see the LICENSE file for more details.  

---

## Support & Feedback 😁
- Questions or suggestions? Contact us via [Fox Jet Studios](https://foxjetstudios.com/contact)  
- Follow us on social media [Fox Jet Studios](https://foxjetstudios.com/followus)  
- Your feedback makes the plugin even better!  

Happy building!
