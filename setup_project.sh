#!/bin/bash

# QuickIdea Project Setup Script
# This script adds the Swift files to the Xcode project

echo "🚀 Setting up QuickIdea project..."

PROJECT_DIR="/Users/elissali/github/other/QuickIdea"
cd "$PROJECT_DIR"

# Check if we're in the right directory
if [ ! -f "QuickIdea.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Cannot find project file"
    exit 1
fi

echo "✅ Found project file"

# Use ruby gem xcodeproj or manual method
if command -v gem &> /dev/null && gem list xcodeproj -i &> /dev/null; then
    echo "📦 Using xcodeproj gem to add files..."

    ruby << 'RUBY'
require 'xcodeproj'

project_path = '/Users/elissali/github/other/QuickIdea/QuickIdea.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find targets
main_target = project.targets.find { |t| t.name == 'QuickIdea' }
widget_target = project.targets.find { |t| t.name == 'QuickIdeaWidgetExtension' }

# Find main group
main_group = project.main_group.find_subpath('QuickIdea', true)

# Files to add to main target
main_files = [
  'QuickIdea/Idea.swift',
  'QuickIdea/ContentView.swift',
  'QuickIdea/IdeaListView.swift',
  'QuickIdea/AddIdeaView.swift',
  'QuickIdea/SettingsView.swift'
]

main_files.each do |file_path|
  file_ref = main_group.new_reference(file_path)
  main_target.source_build_phase.add_file_reference(file_ref)
  puts "✅ Added #{file_path} to QuickIdea target"
end

project.save
puts "✅ Project saved successfully"
RUBY

else
    echo "⚠️  xcodeproj gem not found"
    echo "📖 Please add files manually in Xcode:"
    echo ""
    echo "1. Open QuickIdea.xcodeproj in Xcode"
    echo "2. Right-click 'QuickIdea' folder → Add Files"
    echo "3. Select these files and check 'QuickIdea' target:"
    echo "   - Idea.swift"
    echo "   - ContentView.swift"
    echo "   - IdeaListView.swift"
    echo "   - AddIdeaView.swift"
    echo "   - SettingsView.swift"
    echo ""
    echo "4. Delete SceneDelegate.swift from the project"
    echo ""
    echo "Then build with: Cmd+B"
    exit 0
fi

echo ""
echo "✨ Setup complete! Now you can:"
echo "1. Open the project: open QuickIdea.xcodeproj"
echo "2. Select a simulator"
echo "3. Build and run: Cmd+R"
echo ""
echo "📱 After running, add widgets to your home screen or lock screen!"
