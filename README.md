# test_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Installing flutter
follow this guide: https://docs.flutter.dev/install/quick


## IOS guide
Install latest version of ruby:

`brew upgrade ruby`

`echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc`

`brew link --overwrite ruby`

`sudo gem update --system `

Then restart the terminal,
and follow this guide:
https://docs.flutter.dev/platform-integration/ios/setup

In the project run

`flutter clean`

`flutter pub get`

then

`cd ios`

`pod repo update`

`pod install`
