# ``KitoToasts``

Queued, themeable toast and snackbar notifications for SwiftUI.

## Overview

KitoToasts shows short, dismissible messages from anywhere in your app. A single
``KitoToastCenter`` owns the queue; host it once near the root with
`kitoToastHost(_:placement:)` and share it through the environment or your view
models.

```swift
@main
struct MyApp: App {
    @State private var toasts = KitoToastCenter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(toasts)
                .kitoToastHost(toasts)
                .autoKitoTheme()
        }
    }
}
```

Then show a toast from any screen or view model:

```swift
toasts.show("Profile updated", style: .success)
```

For anything beyond a one-line message, build a ``KitoToast``: add a title,
choose a ``KitoToastStyle`` and ``KitoToastIcon``, attach any number of
``KitoToastAction`` buttons, or pick a ``KitoToastLayout`` such as a card, pill,
banner, glass panel, or a capsule that grows out of the Dynamic Island. The
center's `promise(loading:success:failure:layout:operation:)` shows a loading toast that
turns into success or failure when the work finishes.

Set app-wide fonts, corner radius, icon size, line limits, background, and
haptics with ``KitoToastAppearance`` and the `kitoToastAppearance(_:)` modifier.
Choose ``KitoToastPresentation/stacked`` to pile toasts up instead of queueing
them, and ``KitoToastHostPlacement/window`` to draw them above sheets and
full-screen covers.

## Topics

### Essentials

- ``KitoToastCenter``
- ``KitoToast``
- ``KitoToastHost``

### Content

- ``KitoToastStyle``
- ``KitoToastIcon``
- ``KitoToastTitleStyle``
- ``KitoToastAvatar``
- ``KitoToastProgress``

### Actions

- ``KitoToastAction``
- ``KitoToastActionRole``
- ``KitoToastActionContent``

### Layout and Presentation

- ``KitoToastLayout``
- ``KitoToastPresentation``
- ``KitoToastPosition``
- ``KitoToastHostPlacement``

### Appearance

- ``KitoToastAppearance``
