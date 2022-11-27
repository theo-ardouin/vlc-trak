# TRAK

## Has this ever happened to you?

You're _binging_ a show, but the tracks you want to use are _not_ selected by
default, so you're **forced** to right-click and select your audio/subtitle
track for **each** episode!?

_Oh, the humanity!_

---

Not anymore, thanks to TRAK™!

With TRAK™, you can specify tracks per show using a handy configuration.

_It's that easy`**`!_

## Compatibility

TRAK™ is using VLC `4.X`.

## Installation

To install the extension, go to your VLC installation directory.

| OS      | Path                                                          |
| ------- | ------------------------------------------------------------- |
| Windows | %ProgramFiles%\VideoLAN\VLC (`C:\Program Files\VideoLAN\VLC`) |
| Linux   | /usr/lib/vlc/                                                 |
| Mac     | /Applications/VLC.app/Contents/MacOS/share/                   |

Then, add the `track.lua` from this repository in `lua > extensions`.

## Activation

To activate the extension on VLC, go to `View > TRAK`.

In doubt, you can check the logs (Using `CTRL+M` or `Tools > Messages`).

## Configuration

First, you need to create/edit your TRAK configuration.
It is located in VLC's userdata directory.

| OS      | Path                                                      |
| ------- | --------------------------------------------------------- |
| Windows | %APPDATA%\vlc (`C:\Users\<USER>\AppData\Roaming\vlc`)     |
| Linux   | ~/.local/share/vlc                                        |
| Mac     | /Users/$USER/Library/Application Support/org.videolan.vlc |

You can create a file `trak.xml`. It should be formatted as the following:

```xml
<?xml version="1.0"?>
<config>
    <media audio="japanese" subtitle="1">Fullmetal alchemist</media>
    <media audio="english" subtitle="-1">Andor</media>
    <media audio="0">The Expanse</media>
    <!-- More medias can be added here! -->
</config>
```

For each `media`, you may select the `audio` and `subtitle` attribute.
You can use plain text, and it will try to find the matching track name.

Alternatively, you can use a number (between `0` and `n`) and it will select
the corresponding track.

If you use `-1`, it will mute the track completely.

## File matching

The given key "`Foo bar`" will match the following:

```
../foobar.s01e01.mkv
../FOOBAR/e01.mkv
../foo-bar/s01e01.mkv
../Foo_Bar.mp4
```

It is case-insenstive and discard spaces, comma and underscores.

Because we use the URI given by VLC (e.g `C:\Users\test\Downloads\FooBar\S01\foobar.s01e01.mkv`),
you can use the directory hierarchy.

For example:
```xml
<?xml version="1.0"?>
<config>
    <media audio="1">FooBar\S01</media>
    <media audio="2">FooBar\S02</media>
</config>
```

## Bugs

- On media start, the track settings are not applied:
    https://code.videolan.org/videolan/vlc/-/issues/27558

---

`**`: Not _that_ easy. You still have to write an XML (_yeesh_) configuration
by hand.
