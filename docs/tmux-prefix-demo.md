# Tmux Prefix Highlighting Demo

Your tmux configuration now includes **authentic tmux-dotbar prefix highlighting**!

## How It Works

### Normal State (No Prefix)
- **Session name**: Dark blue background (#303446) with muted purple text (#9399b2)
- **Time**: Same styling on the right side
- **Appearance**: ` session_name ` and ` 14:30 `

### Prefix Active State (After Ctrl+b)
- **Session name**: Bright purple background (#cba6f7) with bold dark text (#303446)
- **Time**: Same bright styling
- **Appearance**: ` session_name ` and ` 14:30 ` (but with purple background)

## Testing the Feature

1. **Start tmux**: `tmux`
2. **Press prefix**: `Ctrl+b` (default prefix key)
3. **Observe**: Session name and time immediately change to bright purple background
4. **Cancel**: Press `Escape` to return to normal, or continue with a tmux command

## Key Features

✅ **Immediate visual feedback** when prefix key is pressed
✅ **Color inversion** from dark blue → bright purple background
✅ **Bold text styling** during prefix mode for better visibility
✅ **Both sides highlighted** - session name (left) and time (right)
✅ **Automatic return** to normal state when prefix is used or cancelled

## Technical Implementation

Based on the original [tmux-dotbar](https://github.com/vaaleyard/tmux-dotbar) plugin, using tmux's built-in `#{?client_prefix,...}` conditional formatting to detect prefix state and dynamically change status bar appearance.

This gives you the exact same visual experience as the original tmux-dotbar plugin while being fully integrated with home-manager configuration!