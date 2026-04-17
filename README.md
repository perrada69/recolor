# RECOLOR

RECOLOR is a small dot command utility for the ZX Spectrum Next that lets you load a custom ULA palette from an `.NXP` file and instantly remap the classic Spectrum colors used by INK, PAPER, and BORDER.

It was originally created to test new features added to ZX PixelPaste, but it quickly became a useful standalone tool for anyone who wants to experiment with the look of classic 48K/128K ULA graphics on the Next.

## What it does

RECOLOR loads a `512-byte .NXP` palette file and uploads it into the `ULA first palette` on the ZX Spectrum Next.

This makes it possible to change the appearance of traditional ULA-based screens and programs without modifying the original game, screen data, or graphics files.

Typical use cases include:

- alternative color styles for older games
- softer or more atmospheric palettes
- stylized loading screens and title screens
- quick palette experiments for classic ULA projects

## Why it exists

The idea came from Bernhard, also known as Luzie67, while experimenting with ZX PixelPaste. It became clear that creating recolored ULA palettes was easy enough, but there was no simple one-command tool to load and apply them directly on the ZX Spectrum Next.

So RECOLOR was written to fill that gap.

## Creating `.NXP` files

The recommended way to create palette files for RECOLOR is with [ZX PixelPaste](https://www.mb-maniax.cz/zxpp/index.html).

Workflow:

1. Save a game or program screen as an SCR file
2. Open it in ZX PixelPaste
3. Switch the Screen Editor to Next mode
4. Open Palette Tools
5. Select `Classic ULA Recolor`
6. Choose the colors you want to remap
7. Export the result as an `.NXP` file

You can also build mappings directly without using an SCR file by working with the full classic ZX Spectrum color set inside ZX PixelPaste.

## Palette file format

RECOLOR expects a `512-byte` `.NXP` file:

- bytes `0-255` = `palLo`
- bytes `256-511` = `palHi`

These two blocks contain the palette data used by the ZX Spectrum Next palette hardware.

## Usage

```txt
.recolor filename.nxp
```

Example:

```txt
.recolor mypalette.nxp
```

## Requirements

- ZX Spectrum Next
- esxDOS / NextZXOS dot command support
- valid `.NXP` palette file

## Download

Releases are available here:

[https://github.com/perrada69/recolor/releases](https://github.com/perrada69/recolor/releases)

## Related tool

ZX PixelPaste:
[https://www.mb-maniax.cz/zxpp/index.html](https://www.mb-maniax.cz/zxpp/index.html)

## Credits

- Idea and inspiration: Bernhard / Luzie67
- Code: Shrek / MB Maniax

## Notes

RECOLOR is intended for classic ULA-style color remapping on the ZX Spectrum Next. It is a simple and practical way to test palette variations and give old screens a fresh look with minimal effort.
