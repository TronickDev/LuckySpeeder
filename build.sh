#!/bin/bash

set -e

# Compile for iPhone arm64
`xcrun --sdk iphoneos -f clang` -dynamiclib -x objective-c -arch arm64 -isysroot `xcrun --sdk iphoneos --show-sdk-path` \
-framework Foundation -framework UIKit -miphoneos-version-min=13.0 \
-o LuckySpeeder-iphone-arm64.dylib LuckySpeeder-iphone.m -O3 -flto

# Compile for macOS arm64
#`xcrun --sdk macosx -f clang` -dynamiclib -x objective-c -arch arm64 -isysroot `xcrun --sdk macosx --show-sdk-path` \
#-framework Foundation -mmacosx-version-min=11.0 \
#-o LuckySpeeder-macos-arm64.dylib LuckySpeeder-macos.m -O3 -flto

# Compile for macOS x86_64
#`xcrun --sdk macosx -f clang` -dynamiclib -x objective-c -arch x86_64 -isysroot `xcrun --sdk macosx --show-sdk-path` \
#-framework Foundation -mmacosx-version-min=10.15 \
#-o LuckySpeeder-macos-x86_64.dylib LuckySpeeder-macos.m -O3 -flto
