## Project Overview
This project is a minimal iOS app built in **SwiftUI**.  
The app allows a user to:
- Enter the name of a Stockholm metro stop.
- Query the SL Transport API (https://www.trafiklab.se/api/our-apis/sl/transport/).
- Show the next departing **metro** trains from that stop.

## Technical Requirements
- **SwiftUI only** — use stock components (`TextField`, `List`, `Button`, `ProgressView`, etc.).
- Networking must use **URLSession** with `async/await`.
- Decode JSON using `Codable` structs.
- Keep the code **clean and minimal** (no unnecessary abstractions).
- Organize code into a simple MVVM-ish style if possible (one API manager, one ContentView).
- Filter departures to **metro only** (`line.transport_mode == "METRO"`).
- Sort departures by **expected time** ascending.

## Future Enhancements
- Allow users to save **favorite stops**.
- Persist last-selected stop in **UserDefaults**.
- Add location-based station suggestions.

## Style & UX
- Keep UI **minimal and native**.  
- Use clear headings, default iOS styling, and avoid custom design.  
- Make error messages user-friendly but short.  