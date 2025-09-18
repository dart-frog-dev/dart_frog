#!/bin/bash

# Ensure mason_cli is installed.
dart pub global activate mason_cli

# Runs `mason bundle` to generate bundles for all bricks within the top level bricks directory.

# Create Dart Frog Brick
mason bundle -s git https://github.com/dart-frog-dev/dart_frog --git-path bricks/create_dart_frog -t dart -o packages/dart_frog_cli/lib/src/commands/create/templates

# Development Dart Frog Server Brick
mason bundle -s git https://github.com/dart-frog-dev/dart_frog --git-path bricks/dart_frog_dev_server -t dart -o packages/dart_frog_cli/lib/src/commands/dev/templates

# Production Dart Frog Server Brick
mason bundle -s git https://github.com/dart-frog-dev/dart_frog --git-path bricks/dart_frog_prod_server -t dart -o packages/dart_frog_cli/lib/src/commands/build/templates

# Create dart frog routes and middlewares
mason bundle -s git https://github.com/dart-frog-dev/dart_frog --git-path bricks/dart_frog_new -t dart -o packages/dart_frog_cli/lib/src/commands/new/templates

dart format ./packages/dart_frog_cli