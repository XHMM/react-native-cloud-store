---
title: Trouble Shooting
sidebar_position: 3
---

## Why my folder and files not visible in iCloud drive folder?

1. make sure your `NSUbiquitousContainers` config in `Info.plist` is correct
2. make sure your path passed to API includes `'Documents'`, for example `'/path-to-icloud-container/Documents/myCustomContent'` but not `'/path-to-icloud-container/myCustomContent'`
3. if above are correct, try to bump your build version in XCode/Info.plist and rebuild

## What is `.xxx.icloud` file?
When reading iCloud dir, you would find files named like `.xxx.icloud`, this format means the file has not downloaded to your local device, it's currently stored on iCloud drive. You can call `persist('xxx')` (don't write like `persist('.xxx.icloud'')` or `persist('.xxx'')`, you will not receive update event) to download it, after download, re-call `readDir` and you will find `.xxx.icloud` become `xxx`, then you can use such as `react-native-fs` to copy it from iCloud container to your app's documents folder.
