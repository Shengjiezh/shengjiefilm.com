#!/bin/bash

# Shengjie Film - Automated Image Optimization Script
# This script automatically optimizes all images in the website
# Run this script whenever you add new images

echo "🎨 Shengjie Film - Image Optimization Script"
echo "=============================================="

# Create optimized directory if it doesn't exist
mkdir -p "images/optimized"

# Function to optimize images in a directory
optimize_directory() {
    local source_dir="$1"
    local target_dir="$2"
    
    if [ ! -d "$source_dir" ]; then
        echo "⚠️  Source directory $source_dir not found, skipping..."
        return
    fi
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    echo "📁 Processing: $source_dir → $target_dir"
    
    # Process all JPEG images
    find "$source_dir" -name "*.jpg" -o -name "*.jpeg" | while read -r image; do
        filename=$(basename "$image")
        target_path="$target_dir/$filename"
        
        # Only process if target doesn't exist or source is newer
        if [ ! -f "$target_path" ] || [ "$image" -nt "$target_path" ]; then
            echo "  🔄 Optimizing: $filename"
            
            # Get original image dimensions
            original_width=$(sips -g pixelWidth "$image" | tail -1 | awk '{print $2}')
            original_height=$(sips -g pixelHeight "$image" | tail -1 | awk '{print $2}')
            
            # Calculate optimal dimensions while maintaining aspect ratio
            # For better quality: use 2000px max width for desktop, 1500px for mobile
            max_width=2000
            max_height=2000
            
            if [ "$original_width" -gt "$max_width" ] || [ "$original_height" -gt "$max_height" ]; then
                # Resize if image is larger than max dimensions
                sips -Z $max_width -s format jpeg -s formatOptions 90 "$image" --out "$target_path" > /dev/null 2>&1
            else
                # Just optimize quality without resizing if image is already small enough
                sips -s format jpeg -s formatOptions 90 "$image" --out "$target_path" > /dev/null 2>&1
            fi
            
            # Get file sizes for comparison
            original_size=$(stat -f%z "$image" 2>/dev/null || stat -c%s "$image" 2>/dev/null)
            optimized_size=$(stat -f%z "$target_path" 2>/dev/null || stat -c%s "$target_path" 2>/dev/null)
            
            if [ "$original_size" -gt 0 ] && [ "$optimized_size" -gt 0 ]; then
                savings=$((original_size - optimized_size))
                savings_percent=$((savings * 100 / original_size))
                echo "    ✅ Saved: ${savings_percent}% (${savings} bytes) - Quality: 90% JPEG"
            fi
        else
            echo "  ⏭️  Skipping: $filename (already optimized)"
        fi
    done
}

# Optimize main portfolio images
echo ""
echo "📸 Optimizing Portfolio Images..."
optimize_directory "images" "images/optimized"

# Optimize travel destination images
echo ""
echo "✈️  Optimizing Travel Destination Images..."

# Get all subdirectories in images folder (excluding optimized)
find "images" -maxdepth 1 -type d ! -name "images" ! -name "optimized" | while read -r dir; do
    dirname=$(basename "$dir")
    optimize_directory "images/$dirname" "images/optimized/$dirname"
done

echo ""
echo "🎯 Optimization Complete!"
echo "=========================="
echo ""
echo "📋 Next Steps:"
echo "1. Add 'loading=\"lazy\"' to new images in HTML files"
echo "2. Update image paths to use 'images/optimized/' instead of 'images/'"
echo "3. Add preload tags for critical new images in <head>"
echo ""
echo "💡 Pro Tips:"
echo "- Run this script after adding new images"
echo "- The script only processes new/changed images"
echo "- All optimized images are saved in 'images/optimized/'"
echo "- Quality settings: 90% JPEG, max 2000px width/height"
echo ""
echo "🚀 Your website is now optimized and ready to deploy!"
