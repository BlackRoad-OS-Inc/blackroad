# RoadWorld Features Documentation

## Overview

RoadWorld is a comprehensive web-based mapping application with advanced features for exploration, measurement, and location management.

## Core Features

### 1. Map Visualization

#### Globe View
- 3D globe projection at low zoom levels
- Atmospheric effects and space rendering
- Smooth transition to Mercator projection
- Star field background

#### Map Styles (5 Available)
- 🛰️ **Satellite**: ESRI World Imagery
- 🗺️ **Streets**: OpenStreetMap tiles
- 🌙 **Dark**: CARTO Dark Matter
- 🏔️ **Terrain**: Stadia Maps Terrain
- 🔀 **Hybrid**: Google satellite + labels

#### Zoom Levels
- **Level 0-3**: Planet View (globe)
- **Level 3-6**: Continent View
- **Level 6-10**: Region/Country View
- **Level 10-14**: City View
- **Level 14-17**: Neighborhood View
- **Level 17-20**: Street Level
- **Level 20-22**: Building Detail

### 2. 3D Buildings 🏢

**New Feature!** Vector-based 3D building extrusion.

- Toggle on/off with 3D button
- Automatically tilts camera to 60° when enabled
- Color-coded by height
- Minimum zoom: 14
- Source: OpenFreemap vector tiles
- Building layer shows:
  - Building footprints
  - Height extrusion
  - Base elevation
  - Smooth zoom transitions

**Usage:**
1. Zoom to a city (level 14+)
2. Click the 🏢 button
3. Camera tilts automatically
4. Buildings appear in 3D

### 3. Custom Markers 🎯

Create and manage custom location markers with categories.

#### Marker Categories
- ⭐ **Favorite**: Personal favorites (#FF6B00)
- 💼 **Work**: Work-related locations (#0066FF)
- 🏠 **Home**: Home locations (#FF0066)
- ✈️ **Travel**: Travel destinations (#7700FF)
- 🍴 **Food**: Restaurants, cafes (#FF9D00)
- 📍 **Custom**: General markers (#00d4ff)

#### Features
- Custom names and descriptions
- Persistent storage (LocalStorage)
- Click to view details in popup
- Delete individual markers
- Teardrop-style marker design
- Coordinate display

**Usage:**
1. Navigate to desired location
2. Click 🎯 marker button
3. Fill in name, category, description
4. Click "Save Marker"
5. Marker appears on map

### 4. Measurement Tools 📏

Precise distance and area measurements using Haversine formula.

#### Distance Measurement
- Click points on map to measure
- Displays total distance
- Shows path with dashed line
- Numbered waypoints
- Units: meters, kilometers

#### Area Measurement
- Click to define polygon
- Calculates enclosed area
- Displays filled polygon
- Shows outline
- Units: m², hectares, km²

**Usage:**
1. Click 🛠️ tools button
2. Select "Measure Distance" or "Measure Area"
3. Click points on map
4. View real-time results
5. Click "Clear Measurements" to reset

**Formulas:**
- **Distance**: Haversine formula for great circle distance
- **Area**: Shoelace formula adjusted for spherical coordinates

### 5. URL Sharing 🔗

Generate shareable links to exact map positions.

#### Shared Parameters
- Latitude and longitude (6 decimal places)
- Zoom level (2 decimal places)
- Bearing (rotation)
- Pitch (tilt angle)
- Map style
- Optional marker flag

**Example URL:**
```
https://roadworld.pages.dev?lat=40.758000&lng=-73.985500&zoom=17.50&bearing=45.00&pitch=60.00&style=satellite
```

**Usage:**
1. Navigate to desired view
2. Click 🔗 share button
3. Link copied to clipboard
4. Share with others
5. Recipients see exact same view

### 6. Location Search

Powered by Nominatim (OpenStreetMap) geocoding.

**Search Examples:**
- `Times Square, New York`
- `Eiffel Tower`
- `48.8584, 2.2945` (coordinates)
- `123 Main St, Boston, MA`
- `Tokyo Tower, Japan`

**Features:**
- Autocomplete suggestions
- Location type detection
- Smart zoom level selection
- Search history tracking
- Keyboard shortcut (Enter)

### 7. Saved Locations 💾

Save favorite locations for quick access.

**Features:**
- Save current view
- Name locations
- Store zoom level
- Click to navigate
- Persistent storage
- View counter in info panel

**Usage:**
1. Navigate to location
2. Click 💾 save button
3. Opens saved locations panel
4. Click any saved location to fly there

### 8. Quick Locations

Pre-configured famous landmarks for instant travel.

**Included Locations:**
- 🗽 Times Square, NYC
- 🗼 Eiffel Tower, Paris
- 🌃 Shibuya Crossing, Tokyo
- 🏛️ Big Ben, London
- 🗽 Statue of Liberty, NYC
- 🌉 Golden Gate Bridge, SF

**Usage:**
- Click any quick location button
- Flies to location with 3D view
- Auto-tilts camera
- Random bearing for variety

### 9. User Geolocation 📍

Find your current location using browser API.

**Features:**
- Request permission on first use
- Accurate positioning
- Adds marker at your location
- Zooms to street level (17)
- Error handling

**Usage:**
1. Click 📍 locate button
2. Allow location permission
3. Map flies to your position
4. Orange marker shows location

### 10. Map Controls

#### Navigation
- **Home 🏠**: Return to globe view
- **North 🧭**: Reset bearing and pitch
- **Zoom +/-**: Zoom in/out
- **Globe 🌐**: Return to planet view

#### Tools
- **3D 🏢**: Toggle buildings
- **Marker 🎯**: Add custom marker
- **Measure 📏**: Open tools panel
- **Share 🔗**: Copy share link
- **Tools 🛠️**: Open full tools menu

#### Keyboard Shortcuts
- **Drag**: Pan and rotate map
- **Scroll**: Zoom in/out
- **Ctrl+Drag**: Tilt camera
- **Right-click+Drag**: Rotate view

### 11. Tools Panel 🛠️

Comprehensive tools menu with organized sections.

#### Measurement Section
- Measure Distance
- Measure Area
- Clear Measurements
- Live results display

#### Markers Section
- Add Marker Here
- View All Markers
- Clear All Markers

#### Share Section
- Copy Share Link
- Export View (planned)

### 12. Real-time Statistics

Live display of current map state.

**Displayed Stats:**
- **Zoom Level**: Current zoom (0-22)
- **Altitude**: Estimated altitude from zoom
- **Resolution**: Meters per pixel
- **Center**: Lat/Lng coordinates
- **Tile Coords**: Z/X/Y tile position
- **Saved Count**: Number of saved locations

**Formats:**
- Altitude: m, km, Mm (megameters)
- Resolution: cm/px, m/px, km/px
- Coordinates: Decimal degrees with N/S/E/W

### 13. Scale Indicators

Visual zoom level guide with 7 levels.

- 🌍 Planet View (0-3)
- 🗺️ Continent (3-6)
- 🏔️ Region/Country (6-10)
- 🏙️ City (10-14)
- 🏘️ Neighborhood (14-17)
- 🏠 Street Level (17-20)
- 🚶 Building Detail (20-22)

Active level highlighted in cyan.

### 14. Notifications

Toast-style notification system.

**Triggers:**
- Link copied to clipboard
- Marker added
- Measurement started
- All markers cleared
- Errors and warnings

**Behavior:**
- Slides in from right
- Auto-dismisses after 3 seconds
- Slide-out animation
- Multiple notifications queue

## Technical Features

### Data Persistence

**LocalStorage Schema:**
```javascript
{
  savedLocations: [],    // Saved locations array
  markers: [],           // Custom markers array
  settings: {
    defaultStyle: 'satellite',
    show3DBuildings: false,
    lastPosition: {
      center: [lng, lat],
      zoom: 1.5,
      pitch: 0,
      bearing: 0
    }
  },
  history: []           // Search history (last 50)
}
```

### Performance Optimizations

- Debounced UI updates
- Efficient tile loading
- Layer caching
- Marker clustering (planned)
- Lazy loading of heavy assets

### Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+
- Mobile browsers (iOS Safari, Chrome Mobile)

## Upcoming Features

### Planned Enhancements

1. **Screenshot Export 📸**
   - Capture current view as PNG
   - Include/exclude UI elements
   - Custom resolution
   - Download or share

2. **Route Planning 🛣️**
   - Point-to-point routing
   - Multiple waypoints
   - Turn-by-turn directions
   - Distance and time estimates

3. **Layer Overlays**
   - Traffic layer
   - Weather radar
   - Terrain contours
   - Population density

4. **Offline Mode**
   - Service worker
   - Tile caching
   - Progressive Web App
   - Offline-first architecture

5. **Advanced Markers**
   - Photo attachments
   - Custom icons
   - Marker clustering
   - Import/export

6. **Analytics Dashboard**
   - Usage statistics
   - Popular locations
   - Search trends
   - User journey tracking

## API Integration

### External Services

- **MapLibre GL**: Map rendering
- **Nominatim**: Geocoding
- **OpenFreemap**: Building vectors
- **ESRI**: Satellite imagery
- **OpenStreetMap**: Street tiles
- **CARTO**: Dark theme
- **Stadia Maps**: Terrain
- **Google**: Hybrid tiles

### Rate Limits

- **Nominatim**: 1 request/second
- **Tile Providers**: No enforced limits (fair use)

## Keyboard Reference

| Action | Keys |
|--------|------|
| Pan | Click + Drag |
| Rotate | Right-click + Drag |
| Tilt | Ctrl + Drag |
| Zoom | Scroll Wheel |
| Search | Enter (in search box) |

## Best Practices

### For Measurements
- Zoom in closer for more accurate distances
- Use globe projection for very large distances
- Click "Clear" before starting new measurement

### For Markers
- Use descriptive names
- Choose appropriate categories
- Add descriptions for context
- Back up important markers

### For Performance
- Clear measurements when not needed
- Limit active markers (< 100)
- Use appropriate zoom levels
- Close panels when done

## Troubleshooting

### Map Won't Load
- Check internet connection
- Clear browser cache
- Try different map style
- Refresh page

### Location Search Not Working
- Check spelling
- Try more specific search
- Use coordinates for precise location
- Wait 1 second between searches (rate limit)

### Markers Not Saving
- Check browser privacy settings
- Enable LocalStorage
- Try different browser
- Export markers before clearing cache

### 3D Buildings Not Showing
- Zoom in closer (level 14+)
- Check if 3D button is active
- Try different location (some areas lack data)
- Refresh page

## Credits

- **MapLibre GL**: Open-source map rendering
- **OpenStreetMap**: Community map data
- **Nominatim**: Geocoding service
- **BlackRoad Systems**: Development and design

## License

MIT License - BlackRoad Systems
