# FaceCode

FaceCode is a fast, local multiplayer (same-device) party game.

One player is the **emoji player** and can ONLY communicate using emojis.
Everyone else are **guessers** and can type guesses.

## Requirements

- Flutter (latest stable)
- Xcode (for iOS) / Android Studio (for Android)

## Setup

1. Install dependencies:

	`flutter pub get`

2. Verify there are no static analysis issues:

	`flutter analyze`

3. Run tests:

	`flutter test`

## Run

- iOS Simulator:

  `flutter run -d ios`

- Android emulator/device:

  `flutter run -d android`

You can also run without specifying a device:

`flutter run`

## How to Play (Local Multiplayer)

1. Create a room.
2. Add players in the lobby (pass-and-play style).
3. Start the game (host only).
4. On the Game screen, tap **Active player** to pick who is holding the phone.
5. The emoji player uses the emoji keyboard; guessers type their guesses.
6. Rounds are 60 seconds. The emoji player rotates every round.

## Notes

- Version 1 supports both **Offline (same device)** pass-and-play mode and **Local Wi‑Fi** multiplayer (devices on the same Wi‑Fi network).
- For Wi‑Fi mode the app uses UDP broadcast discovery and a lightweight WebSocket server. Both devices must be on the same network and local network permissions must be granted on the device.
- The app name is **FaceCode** on both Android and iOS.

### Wi‑Fi Troubleshooting

- If auto-discovery fails, use the host's room code on the Join screen.
- Ensure Wi‑Fi is enabled and both devices are on the same subnet. Some guest/enterprise networks block local device discovery.
- On iOS you may be prompted to allow local network access; accept to enable discovery.
