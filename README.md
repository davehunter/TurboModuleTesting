# TurboModuleTesting

## React Native TurboModule Testing Support for CMake

The objective of this project is to make it convenient to write native unit tests for React Native TurboModules. The current focus is on C++, but other native languages should work as long as they can compile for macOS.

The included CMake utilities leverage the native code installed via CocoaPods as part of a React Native iOS app, and recompile it for macOS. This lets you reuse your app’s existing native dependencies without needing a separate setup.

A nice side benefit of compiling for macOS is that you’ll get a `compile_commands.json`, which you can feed into language server tooling for excellent code navigation and IDE support.

## Example

You can see an example of how to use this library here:  
https://github.com/davehunter/TurboModuleTestingExample

## Requirements

- CMake
- Ninja
- Xcode (with Command Line Tools installed)

## Usage

1. Include this repo in your project. I recommend using CMake’s `FetchContent_Declare`. See the example repo for a working setup.
2. Call `TurboModuleTesting_ConfigureBasedOnApp("${app_path}")` and pass it the full path to a React Native app to use for dependencies.  
   **Important:** You should have already installed dependencies for this app (e.g. via CocoaPods) *before* configuring with CMake.
3. Call `TurboModuleTesting_AddTurboModuleDependencies(${turbomodule_target} "${turbomodule_name}")` for each TurboModule you want to compile.
4. Since Android uses CMake, if you’re careful you can reuse much of the same CMake code for both Android and macOS.  
   **Note:** Do not call any of this library’s functions when building for Android.

## Notes

This is an experimental project. It has only been tested with React Native 0.83.1.
