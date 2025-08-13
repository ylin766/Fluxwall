# Fluxwall

Fluxwall is a free, lightweight macOS app dedicated to dynamic video wallpapers on your desktop. It gives you full DIY control to preview, customize, and animate your wallpaper experience.

## Features

- Video and image wallpaper support
- Drag & drop file selection
- Transition effects with customizable duration
- Multi-display support
- Click-to-preview transition effects
- Language support (English/中文)

## Supported Formats

MP4, MOV, JPG, PNG

## Requirements

macOS 12.0+

## Build from Source

### Prerequisites

- Xcode 14.0+
- macOS 12.0+

### Building

1. Clone the repository:
   ```bash
   git clone https://github.com/ylin766/Fluxwall.git
   cd Fluxwall
   ```

2. Build the DMG installer:
   ```bash
   ./build_dmg.sh
   ```

3. The script will:
   - Build the Release version of Fluxwall
   - Create `Fluxwall.dmg` in the project root

### Installation

1. Open the generated `Fluxwall.dmg` file
2. Drag `Fluxwall.app` to the `Applications` folder
3. Launch Fluxwall from Applications or Spotlight

### Usage

1. Launch Fluxwall
2. Drag and drop video files or use the file picker
3. Customize transition effects and duration
4. Enjoy your dynamic wallpaper!
