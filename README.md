!! - THIS IS A FORK - !!

Please note, a lot of things I add just brainstorming and not even work. I adjust this just to suite me better for playing Hearthstone Battlegrounds.

Goals:
 - 1. working iPhone OS Version
 - 2. working MacOS arm64 Version
 - 3. working MacOS x86 Version (maybe not needed)
 - 4. working Windows 10/11 Version

1.
He (@kekeimiku) already made the version working for iPhone OS (tested with iOS 16.1.2 injected via TrollFolls).
I just adjusted some things. Should work with injection into the IPA to Sideload/installing or just injection with TrollFolls will work.

2.
He (@kekeimiku) is working on this, but you can already use it by creating a IPA with the LuckySpeeder included (injection into the framework is important) to run it with Playcover.

3.
As this will only work on MacOS up to 10.13.6 this is not really goal but just nice to have. Still not needed as all new MacBooks are ARM64 where you can Playcover in order to use the iPhone OS version.

4.
I'm not that deep into this stuff, but this code already helped a lot to learn. I got Hearthstone working to run on 10f Time.timeScale by adjusting things via DNSpy as the DLL files are not encrypted.
So far so good. I will try to create something similar to be injectable as DLL or replacing the DLLs within the Hearthstone folder.

For me, it is just fun :)

@kekeimiku looks to work on a version for Apple Vision.


@kekeimiku README file content:
# Lucky Speeder

> Support (Jailbreak/Jailed) iphoneos-version>=13.0

## What's this

Hacking Applications: Four modes are available for controlling Game/Ads speed.

It is not guaranteed to work for all programs; some luck may be required.

Click ♥️ ♠️ ♣️ ♦️ to switch mode.

Click ◀◀ or ▶▶ to adjust speed.

Click ▶ ⏸ to start or stop.

## Demo Video

https://github.com/user-attachments/assets/a2b7b4c2-d7c7-47e8-83b7-be36b3328502

## How to use

Inject [LuckySpeeder.dylib](https://github.com/kekeimiku/LuckySpeeder/releases) into your IPA file.

Google Search: [How to inject dylib into ipa](https://www.google.com/search?client=safari&rls=en&q=How+to+inject+dylib+into+ipa)

PS: You can work without injecting tools like CydiaSubstrate or Substitute.

## TODO

- [x] Support PlayCover IOS App

- [x] Speed up common games

- [ ] Speed ​​up common ads

- [ ] Hide Control Menu

## Tested Games

[WarmSnow](https://apps.apple.com/us/app/warm-snow/id6447508479)

[Hearthstone](https://apps.apple.com/us/app/hearthstone/id625257520)

[Brotato](https://apps.apple.com/us/app/brotato/id6445884925)

[Subway Surfers](https://apps.apple.com/us/app/subway-surfers/id512939461)

[Laya's Horizon](https://apps.apple.com/us/app/layas-horizon/id1615116545)

And more...

## FAQ

### Why does changing the speed have no effect in some games?

1. If possible, try turning off VSync in your game.

2. The game’s anti-cheat system might be preventing this.

3. The game uses a special timer, which LuckySpeeder currently cannot handle.
