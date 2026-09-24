# KitoToasts

**[Documentation](https://wyksofts-inc.github.io/KitoToasts/documentation/kitotoasts/)**

Queued, themeable toast/snackbar notifications for SwiftUI — customizable
title size, bold emphasis, custom or hidden icons, multiple action buttons,
and an app-wide appearance config.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoToasts.git", from: "1.1.0"),
```

## Setup — host once at the root

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

## Samples

**Simple success/error:**
```swift
toasts.show("Profile updated", style: .success)
toasts.show("Could not connect", style: .error)
```

**Custom duration:**
```swift
toasts.show(KitoToast(message: "Syncing…", style: .info, duration: 1.5))
```

**A prominent banner — title + message, large title, bold:**
```swift
toasts.show(KitoToast(
    title: "Payment successful",
    message: "Order #1234 has been confirmed and will arrive by 5:30 PM.",
    style: .success,
    titleStyle: .large,
    isBold: true
))
```

**Custom icon, or no icon at all:**
```swift
toasts.show(KitoToast(message: "New badge unlocked!", style: .success, icon: .custom("trophy.fill")))
toasts.show(KitoToast(message: "Synced", icon: .none))
```

**Multiple action buttons, with roles (does not auto-dismiss):**
```swift
toasts.show(KitoToast(
    title: "Item deleted",
    message: "\"Blue Hoodie\" was removed from your cart.",
    style: .warning,
    actions: [
        KitoToastAction(title: "Undo", role: .primary) { viewModel.undoRemove() },
        KitoToastAction(title: "Dismiss", role: .cancel) {},
    ]
))
```

**One-off accent color override, independent of `style`:**
```swift
toasts.show(KitoToast(message: "Achievement unlocked", icon: .custom("star.fill"), accentColor: .purple))
```

**Background — color, gradient, or image, per toast or app-wide:**
```swift
// One celebratory toast with a gradient background
toasts.show(KitoToast(
    title: "Level up!",
    message: "You've reached level 12.",
    icon: .custom("bolt.fill"),
    backgroundStyle: .gradient(.linear(.purple, .indigo))
))

// An image background with a dark tint so light text stays legible
toasts.show(KitoToast(
    message: "New season available",
    backgroundStyle: .image(.url(seasonBannerURL), overlayTint: .black.opacity(0.35))
))

// Every toast in the app defaults to a solid brand color instead of material
RootView()
    .kitoToastHost(toasts)
    .kitoToastAppearance(KitoToastAppearance(backgroundStyle: .color(.indigo)))
```

`KitoBackgroundStyle` (from `KitoCore`) is the same shared background type
every Kito kit's appearance struct composes — `.color`, `.gradient`
(`KitoGradient`, linear/radial/angular), `.material` (the original look),
or `.image(.asset/.systemImage/.url, overlayTint:)`.

**App-wide appearance — fonts, corner radius, icon size, line limits:**
```swift
RootView()
    .kitoToastHost(toasts)
    .kitoToastAppearance(KitoToastAppearance(
        largeTitleFont: .system(size: 22, weight: .heavy, design: .rounded),
        mediumTitleFont: .system(size: 16, weight: .semibold),
        cornerRadius: 24,
        showsAccentBar: false,
        iconSize: 22,
        maxWidth: 420
    ))
```

**From a checkout ViewModel:**
```swift
@Observable final class CheckoutViewModel {
    let toasts: KitoToastCenter
    func submitPayment() async {
        do {
            try await api.pay()
            toasts.show("Payment successful", style: .success)
        } catch {
            toasts.show("Payment failed — try again", style: .error)
        }
    }
}
```

**Swipe to dismiss** is built in — a vertical drag over 50pt dismisses the
current toast early, with rubber-band resistance as you drag.

## Layouts, stacks, promises and undo

**Layouts.** Pass `layout:`: `.card` (default), `.pill`, `.banner` (edge to edge in the accent
colour), `.glass`, or `.island` (a black capsule that grows out of the Dynamic Island).

```swift
toasts.show(KitoToast(title: "AirPods connected", message: "Battery 84%", icon: .custom("airpods"), layout: .island))
toasts.show(KitoToast(message: "Achieng sent you KES 2,000", style: .success,
                      avatar: KitoToastAvatar(initials: "AO"), layout: .glass))
```

**Stack instead of queue.** New toasts land on top and older ones peek out behind; tap to fan
them out (auto-dismiss pauses while they're fanned out).

```swift
@State private var toasts = KitoToastCenter(presentation: .stacked)    // or .stack(maxVisible: 5)
```

**Promise.** A loading toast that turns into success or error when the work finishes:

```swift
try await toasts.promise(loading: "Paying KES 1,250…", success: "Paid", failure: "Payment failed") {
    try await api.pay()
}
```

**Undo with a countdown.** The ring empties over `duration`, then the toast goes:

```swift
toasts.show(KitoToast(message: "Chat deleted", actions: [KitoToastAction(title: "Undo") { restore() }],
                      duration: 5, showsCountdown: true))
```

Toasts play a success, warning or error haptic as they appear; turn it off with
`KitoToastAppearance(playsHaptics: false)`.

## Every customization knob

| Where | What |
| --- | --- |
| `KitoToast.title` | Optional prominent headline above `message` |
| `KitoToast.titleStyle` | `.large` / `.medium` / `.small` — which appearance font slot to use |
| `KitoToast.isBold` | Bolds both title and message |
| `KitoToast.icon` | `.automatic` (from `style`), `.custom(systemName)`, or `.none` |
| `KitoToast.accentColor` | Overrides the style-derived accent bar/icon color for one toast |
| `KitoToast.backgroundStyle` | Per-toast color/gradient/image background override |
| `KitoToast.actions` | Any number of `KitoToastAction`s, each with a `role` (`.primary`/`.destructive`/`.cancel`) |
| `KitoToastAppearance` | App-wide fonts, corner radius, accent bar visibility, icon size, line limits, max width, default background |

## License

MIT
