#!/bin/sh
echo "Running Dart format check..."

# Run formatter in check mode (fails if changes are needed)
dart format --set-exit-if-changed .

if [ $? -ne 0 ]; then
  echo "Code is not formatted. Please run 'dart format .' in the terminal."
  exit 1
fi
echo "Code is properly formatted."