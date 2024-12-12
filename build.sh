#!/bin/bash

set -e

# compile for iphone arm64
`xcrun --sdk iphoneos -f clang` -dynamiclib -x objective-c -arch arm64 -isysroot `xcrun --sdk iphoneos --show-sdk-path` -framework Foundation -framework UIKit -miphoneos-version-min=13.0 -o LuckySpeeder-iphone-arm64.dylib LuckySpeeder.m -O3 -flto

# compile for macos arm64
`xcrun --sdk iphoneos -f clang` -dynamiclib -x objective-c -arch arm64 -isysroot `xcrun --sdk iphoneos --show-sdk-path` -framework Foundation -framework UIKit -miphoneos-version-min=13.0 -o LuckySpeeder-macos-arm64.dylib LuckySpeeder.m -O3 -flto

# compile for macos x86
`xcrun --sdk iphoneos -f clang` -dynamiclib -x objective-c -arch arm64 -isysroot `xcrun --sdk iphoneos --show-sdk-path` -framework Foundation -framework UIKit -miphoneos-version-min=13.0 -o LuckySpeeder-macos-x86.dylib LuckySpeeder.m -O3 -flto
