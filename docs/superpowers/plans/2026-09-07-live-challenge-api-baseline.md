Base HEAD: `f7c08dd5955073158210c80016ef361b63b16e01`

Selected GameKit API surface for Live Challenge V1:

- `GKLocalPlayer.authenticateHandler` for local-player initialization and Game Center sign-in UI.
- `GKLocalPlayerListener` for invite and other player-facing Game Center events.
- `GKMatchRequest` for a 1-vs-1 real-time match request with explicit `minPlayers = 2` and `maxPlayers = 2`.
- `GKMatchmakerViewController` for the Game Center invitation / friend-picker UI.
- `GKMatchmakerViewControllerDelegate` for accept, cancel, error, and `didFindMatch:` lifecycle handling.
- `GKMatch` and `GKMatchDelegate` for peer connection state and real-time data exchange once the match is established.

Compatibility notes for the current repository target:

- The Xcode project deployment target is iOS 15.0.
- Apple’s current documentation lists the selected real-time multiplayer / invitation APIs as available on iOS, iPadOS, Mac Catalyst, tvOS, and visionOS, which is compatible with the project’s iOS 15.0 target.
- Use `GKLocalPlayer.authenticateHandler`; do not reintroduce deprecated `authenticateWithCompletionHandler:`.
- Use the Game Center matchmaker UI and real-time `GKMatch` session APIs; do not rely on deprecated legacy Game Center entry points.

Protected Classic gameplay hashes:

- `spritybird/Classes/Scenes/Scene.m` → `50c6f4542d0a849f1122dcee726280bd867b049fd651dbd8b5e0df4ade2bc4f9`
- `spritybird/Classes/Scenes/BirdNode.m` → `a0c050e3d2fba192fa0584a6d035306f235f690e7924be192b9d7d1db73d63b4`
- `spritybird/Classes/Scenes/SKScrollingNode.m` → `5594f59de2c920747012fc977d2bf62aea9d4ffb0bb64e475785a2511d5c435f`
- `spritybird/Classes/Models/Score.m` → `3276c37c32479aa793b940a8b218787f6753cd9a9e74c03dbc7746bf0aad2ac4`
