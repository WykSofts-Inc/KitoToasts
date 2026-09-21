# KitoToasts

Queued, themeable toast/snackbar notifications for SwiftUI.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoToasts.git", from: "1.0.0"),
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

**Persistent, with an action (does not auto-dismiss):**
```swift
toasts.show(KitoToast(
    message: "Item removed",
    style: .warning,
    action: KitoToastAction(title: "Undo") { viewModel.undoRemove() }
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

**Swipe to dismiss** is built in — a horizontal drag over 40pt dismisses the
current toast early.

## License

MIT
