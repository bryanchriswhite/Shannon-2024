# 🎊 Shannon ecosystem development 2024 🎊

![shannon_2024_15s.gif](shannon_2024_15s.gif)

## Dependencies

- [Gource](https://gource.io/)
- [FFmpeg](https://github.com/FFmpeg/FFmpeg)

## Generating visualizations

```bash
git clone https://github.com/bryanchriswhite/shannon-2024.git --recurse-submodules
cd shannon-2024/gource

# Interactive visualization
./gource.sh

# Recording visualization
./gource.sh --record
# OR
./gource.sh --output shannon_2024.webm
```