# Heads-Up Display for Apple Vision Pro

A hybrid HUD system for visionOS that combines **ornaments** (floating UI) and **WidgetKit widgets** (spatial monitoring) to display external data sources.

## Features

### 🎯 Ornament-Based HUD
- **Floating UI elements** that attach to your window/view
- Three display styles: `compact`, `detailed`, and `minimal`
- Real-time data updates from external sources
- Configurable positioning (top, bottom, leading, trailing)

### 📍 Spatial Widgets
- **WidgetKit widgets** that pin to surfaces in your environment
- Support for all system widget sizes (small, medium, large)
- visionOS-specific features:
  - Glass and paper textures
  - Elevated and recessed mounting styles
  - Proximity-aware layouts (adapts based on distance)
- Timeline-based updates (every 5 minutes)

### 🔌 Plugin System
**Dynamic plugin architecture** allowing external services to provide data:
- **Plugin discovery**: Automatically discover available plugins from any server
- **Multiple authentication methods**: API key, Bearer token, OAuth2 (planned)
- **Flexible data formats**: Numbers, strings, integers, booleans, arrays
- **Built-in plugin manager**: Add, configure, and manage plugins from the app
- **Developer-friendly API**: Simple JSON API specification (v1.0)

Built-in examples:
- **Weather data** (example API integration)
- **System metrics** (CPU, memory, etc.)
- **Custom API endpoints** (via plugin specification)

## Project Structure

```
hdsup/
├── hdsup/                              # Main app
│   ├── Models/
│   │   ├── HUDDataSource.swift         # Data models and source protocols
│   │   └── PluginSpecification.swift   # Plugin API specification
│   ├── Services/
│   │   ├── HUDDataService.swift        # Data fetching and management
│   │   └── PluginManager.swift         # Plugin discovery and loading
│   ├── Views/
│   │   ├── Ornaments/
│   │   │   └── HUDOrnamentView.swift   # Ornament UI components
│   │   └── PluginManagementView.swift  # Plugin configuration UI
│   ├── AppModel.swift                  # App-wide state management
│   ├── ContentView.swift               # Main window with ornaments
│   └── ImmersiveView.swift             # Immersive space integration
├── HUDWidgetExtension/                 # Widget extension
│   ├── HUDWidget.swift                 # Widget implementation
│   └── HUDWidgetBundle.swift           # Widget bundle
└── docs/                               # Documentation
    ├── PLUGIN_API_SPECIFICATION.md     # Plugin API spec
    ├── PLUGIN_EXAMPLES.md              # Implementation examples
    └── DEVELOPER_GUIDE.md              # Complete developer guide
```

## Getting Started

### Prerequisites
- Xcode 15.2 or later
- visionOS 1.0 or later SDK
- Apple Vision Pro or visionOS Simulator

### Installation

1. Clone the repository:
```bash
git clone https://github.com/michyul/hdsup.git
cd hdsup
```

2. Open the project in Xcode:
```bash
open hdsup.xcodeproj
```

3. Build and run on the visionOS Simulator or Apple Vision Pro

### Configuring Data Sources

#### Using the Plugin System (Recommended)

1. **Open Plugin Manager** from the main window
2. **Add Plugin** by entering a plugin server URL
3. **Discover** available plugins automatically
4. **Configure** authentication (API key, bearer token)
5. **Enable/Disable** plugins as needed

Example plugin URL: `https://your-plugin-server.com`

The app will:
- Call `/plugins/discover` to find available plugins
- Let you select which plugins to enable
- Automatically fetch data from enabled plugins
- Display data in ornaments and widgets

#### For Plugin Developers

**Build your own HUD plugins!** See the comprehensive documentation:

- **[Plugin API Specification](docs/PLUGIN_API_SPECIFICATION.md)** - Complete API spec
- **[Plugin Examples](docs/PLUGIN_EXAMPLES.md)** - Working examples in Node.js, Python, Go, PHP
- **[Developer Guide](docs/DEVELOPER_GUIDE.md)** - Step-by-step implementation guide

**Quick Start for Developers:**

1. Implement two HTTP endpoints:
   - `/plugins/discover` - Returns available plugins
   - `/plugins/yourplugin` - Returns formatted data

2. Deploy to any HTTPS server

3. Users add your plugin URL in the app

**Example minimal plugin (Node.js):**

```javascript
app.get('/plugins/discover', (req, res) => {
  res.json({
    apiVersion: "1.0.0",
    plugins: [{
      metadata: {
        id: "com.example.myplugin",
        name: "My Plugin",
        version: "1.0.0",
        // ... more metadata
      },
      endpoint: "/plugins/data"
    }]
  });
});

app.get('/plugins/data', (req, res) => {
  res.json({
    apiVersion: "1.0.0",
    plugin: { /* metadata */ },
    data: {
      value: { number: 42 },
      metrics: { unit: { string: "%" } },
      collectedAt: new Date().toISOString()
    },
    timestamp: new Date().toISOString()
  });
});
```

See full examples in the [docs/](docs/) directory.

#### Legacy: Creating Custom Data Sources (Code-based)

For simple use cases, you can implement the `HUDDataSource` protocol:

```swift
struct MyCustomDataSource: HUDDataSource {
    let id = UUID()
    let name = "My Data"
    let iconName = "chart.bar"
    
    func fetchData() async throws -> HUDData {
        let value = try await fetchFromAPI()
        return HUDData(
            title: "My Metric",
            value: "\(value)",
            unit: "units",
            metadata: ["extra": "info"]
        )
    }
}
```

Then add to `AppModel`:
```swift
appModel.hudDataService.addDataSource(MyCustomDataSource())
```

## Usage

### Ornament Controls

The main window provides toggles to control ornament visibility:
- **Top Ornament**: Compact view at the top of the window
- **Bottom Ornament**: Detailed view at the bottom
- **Side Ornaments**: Minimal views on the leading edge

### Widgets

To add a widget to your visionOS space:
1. Open the Widget Gallery in visionOS
2. Find "HUD Monitor" widgets
3. Select a size (small, medium, or large)
4. Pin it to a surface in your environment

The widget will automatically:
- Fetch data every 5 minutes
- Adapt its layout based on viewing distance
- Support both glass and paper textures

## Customization

### Ornament Styles

Modify `HUDOrnamentView.swift` to customize the appearance:
- `.compact`: Small, single-line display
- `.detailed`: Full information with metadata
- `.minimal`: Ultra-compact for side panels

### Widget Mounting

Configure widget mounting in `HUDWidget.swift`:

```swift
.supportedMountingStyles([.elevated, .recessed])  // Both styles
.supportedMountingStyles([.recessed])             // Wall-mounted only
.widgetTexture(.glass)                            // Glass effect
.widgetTexture(.paper)                            // Poster-like
```

### Update Intervals

Adjust update frequency:

**Ornaments** (in `ContentView.swift`):
```swift
appModel.hudDataService.startAutoUpdate(interval: 30) // 30 seconds
```

**Widgets** (in `HUDWidget.swift`):
```swift
let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
```

## Architecture

### Data Flow

```
External API
    ↓
HUDDataSource.fetchData()
    ↓
HUDDataService (manages multiple sources)
    ↓
    ├─→ Ornaments (real-time, 30s updates)
    └─→ Widgets (timeline-based, 5min updates)
```

### Key Components

- **`HUDDataSource`**: Protocol for data sources
- **`HUDData`**: Standardized data container
- **`HUDDataService`**: Manages fetching and caching
- **`HUDOrnamentView`**: SwiftUI ornament UI
- **`HUDWidget`**: WidgetKit spatial widget

## Advanced Features

### Proximity Awareness (Widgets)

Widgets automatically adapt to viewing distance using `levelOfDetail`:

```swift
@Environment(\.levelOfDetail) var levelOfDetail

var fontSize: Font {
    levelOfDetail == .simplified ? .largeTitle : .title
}
```

### Rendering Modes

Widgets support multiple rendering modes:
- **Full Color**: Default rich appearance
- **Accented**: Themed with user's color preference
- **Vibrant**: Lock Screen style (if applicable)

## Troubleshooting

### Widget Extension Not Building

You may need to manually configure the Widget Extension target in Xcode:
1. Select the project in Xcode
2. Add a new Widget Extension target
3. Copy the widget files into the new target

### Data Not Updating

Check:
- Network permissions in `Info.plist`
- API endpoint accessibility
- Update interval settings

## Contributing

This is a personal project, but feel free to fork and customize for your needs.

## License

MIT License - See LICENSE file for details

## Acknowledgments

- Built with SwiftUI, RealityKit, and WidgetKit
- Designed for Apple Vision Pro
- Follows visionOS Human Interface Guidelines
