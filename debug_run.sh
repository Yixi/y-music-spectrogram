#!/bin/bash

echo "Building debug version..."
swift build -c debug

echo "Running YMusicSpectrogram in debug mode..."
echo "Logs will appear below. Press Ctrl+C to stop."
echo "----------------------------------------"

./.build/debug/YMusicSpectrogram
