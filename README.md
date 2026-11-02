# ProtonShelf

A tiny macOS menu bar app: one atom icon that drops down a list of your installed Proton apps (VPN, Pass, Drive, Mail Bridge…).

- Click an app to open it or bring its window forward.
- Hold ⌥ while the menu is open to quit an app instead.
- A green dot marks apps that are running.
- "Open All" launches every Proton app that isn't running.

Any app in `/Applications` or `~/Applications` whose name starts with "Proton" is listed automatically.

Pair it with a menu bar hider (Hidden Bar, Ice, Bartender) to tuck the Proton apps' own icons away.

## Build

```sh
./build.sh            # builds build/ProtonShelf.app
./build.sh --install  # also copies it to /Applications
```

Requires macOS 15+ and Swift 6.

## License

MIT
