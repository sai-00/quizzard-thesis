#!/bin/sh
echo "Running Flutter format check..."
dart format --set-exit-if-changed .

if [ $? -ne 0 ]; then
  echo "Code is not formatted. Please run 'dart format .' in the terminal."
  exit 1
fi

echo "Running Flutter analyze..."
flutter analyze

if [ $? -ne 0 ]; then
  echo "Flutter analyze found issues. Please fix them before committing."
  exit 1
fi

echo "Running Flutter tests..."
flutter test

if [ $? -ne 0 ]; then
  echo "Some tests failed. Please fix before committing."
  exit 1
fi

echo "Pre-commit checks passed!"
