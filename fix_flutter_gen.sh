#!/bin/bash

# This script adds the flutter_gen package to package_config.json
# Run this before building in Xcode if you get flutter_gen import errors

PACKAGE_CONFIG=".dart_tool/package_config.json"

if [ ! -f "$PACKAGE_CONFIG" ]; then
    echo "Error: $PACKAGE_CONFIG not found"
    exit 1
fi

# Use Python to add flutter_gen to package_config.json
python3 << 'EOF'
import json

config_file = ".dart_tool/package_config.json"

# Read the package_config.json
with open(config_file, 'r') as f:
    config = json.load(f)

# Check if flutter_gen already exists
has_flutter_gen = any(pkg['name'] == 'flutter_gen' for pkg in config['packages'])

if not has_flutter_gen:
    # Find the weight_tracker package index
    weight_tracker_index = next(i for i, pkg in enumerate(config['packages']) if pkg['name'] == 'weight_tracker')

    # Insert flutter_gen before weight_tracker
    flutter_gen_entry = {
        "name": "flutter_gen",
        "rootUri": "../.dart_tool/flutter_gen",
        "packageUri": "gen_l10n/",
        "languageVersion": "3.0"
    }

    config['packages'].insert(weight_tracker_index, flutter_gen_entry)

    # Write back
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=2)

    print("✓ flutter_gen added to package_config.json")
else:
    print("✓ flutter_gen already exists in package_config.json")
EOF

echo "Now you can build the app in Xcode"
