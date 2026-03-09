# 📱 Mobile App Quick Start

## Option 1: Progressive Web App (Fastest!)

Your web visualizers already work on mobile! Just:

1. **Open on mobile browser**:
   ```
   http://YOUR_IP:8000/pixel-world.html
   http://YOUR_IP:8000/pixel-world-3d.html
   ```

2. **Add to home screen**:
   - iOS: Safari > Share > Add to Home Screen
   - Android: Chrome > Menu > Add to Home Screen

3. **Works offline** with service worker (add this):

```html
<!-- Add to your HTML -->
<script>
if('serviceWorker' in navigator){
  navigator.serviceWorker.register('/sw.js')
}
</script>
```

## Option 2: React Native App (15 min setup)

### Quick Setup

```bash
npx react-native init BlackRoadMetaverse
cd BlackRoadMetaverse
npm install react-native-svg react-native-canvas
```

### App.tsx

```tsx
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';

const { width, height } = Dimensions.get('window');

export default function App() {
  const [agents, setAgents] = useState([]);
  const [connected, setConnected] = useState(false);
  
  useEffect(() => {
    const ws = new WebSocket('ws://192.168.4.28:8765');
    
    ws.onopen = () => setConnected(true);
    ws.onclose = () => setConnected(false);
    
    ws.onmessage = (e) => {
      try {
        const data = JSON.parse(e.data);
        if (data.agent) {
          setAgents(prev => [...prev, {
            id: data.agent.id,
            name: data.agent.name,
            x: Math.random() * width,
            y: Math.random() * height,
            color: '#FF1D6C'
          }]);
        }
      } catch (err) {}
    };
    
    return () => ws.close();
  }, []);
  
  return (
    <View style={styles.container}>
      <Text style={styles.title}>🌌 BLACKROAD METAVERSE</Text>
      <Text style={styles.status}>
        {connected ? '🟢 Connected' : '🔴 Disconnected'}
      </Text>
      <Text style={styles.count}>Agents: {agents.length}</Text>
      
      {agents.map((agent) => (
        <View
          key={agent.id}
          style={[styles.agent, {
            left: agent.x,
            top: agent.y,
            backgroundColor: agent.color
          }]}
        />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a'
  },
  title: {
    position: 'absolute',
    top: 50,
    left: 20,
    color: '#FF1D6C',
    fontSize: 18,
    fontWeight: 'bold'
  },
  status: {
    position: 'absolute',
    top: 80,
    left: 20,
    color: '#F5A623',
    fontSize: 14
  },
  count: {
    position: 'absolute',
    top: 105,
    left: 20,
    color: '#2979FF',
    fontSize: 14
  },
  agent: {
    position: 'absolute',
    width: 10,
    height: 10,
    borderRadius: 5
  }
});
```

### Run

```bash
# iOS
npx react-native run-ios

# Android
npx react-native run-android
```

## Option 3: Flutter App (Cross-platform)

```bash
flutter create blackroad_metaverse
cd blackroad_metaverse
flutter pub add web_socket_channel
```

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

void main() => runApp(MetaverseApp());

class MetaverseApp extends StatefulWidget {
  @override
  _MetaverseAppState createState() => _MetaverseAppState();
}

class _MetaverseAppState extends State<MetaverseApp> {
  final channel = WebSocketChannel.connect(
    Uri.parse('ws://192.168.4.28:8765'),
  );
  
  List<Agent> agents = [];
  
  @override
  void initState() {
    super.initState();
    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['agent'] != null) {
        setState(() {
          agents.add(Agent(
            name: data['agent']['name'],
            color: Colors.pink,
          ));
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF0a0a0a),
        body: Stack(
          children: [
            ...agents.map((a) => Positioned(
              left: a.x,
              top: a.y,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: a.color,
                  shape: BoxShape.circle,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
}

class Agent {
  String name;
  Color color;
  double x = 100;
  double y = 100;
  
  Agent({required this.name, required this.color});
}
```

## Deployment

### iOS (TestFlight)
```bash
# Build
xcodebuild -workspace ios/BlackRoadMetaverse.xcworkspace \
  -scheme BlackRoadMetaverse \
  -configuration Release \
  archive

# Upload to TestFlight via Xcode
```

### Android (Play Store)
```bash
cd android
./gradlew bundleRelease

# Upload to Play Console
# File: app/build/outputs/bundle/release/app-release.aab
```

---

**Your metaverse is now mobile! 📱**
