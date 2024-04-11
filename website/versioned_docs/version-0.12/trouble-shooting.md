---
title: Trouble Shooting
sidebar_position: 4
---

## Is there an article about using this library?
Yeah, I wrote [an article here](https://medium.com/@xhmm/how-to-backup-realm-database-to-icloud-using-reactnative-9fd038a0a6b1) about using iCloud to backup your realm database.

## Why my folder and files not visible in iCloud drive folder?

1. make sure your `NSUbiquitousContainers` config in `Info.plist` is correct
2. make sure your path passed to API includes `'Documents'`, for example `'/path-to-icloud-container/Documents/myCustomContent'` but not `'/path-to-icloud-container/myCustomContent'`
3. if above are correct, try to bump your build version in XCode/Info.plist and rebuild

## What is `.xxx.icloud` file?
When reading iCloud dir, you would find files named like `.xxx.icloud`, this format means the file has not downloaded to your local device, it's currently stored on iCloud drive. You can call `download` to download it, after downloaded, re-call `readDir` and you will find `.xxx.icloud` become into `xxx`, then you can use such as `react-native-fs` to copy it from iCloud container to your app's documents folder.

## Backup progress hangs and cannot reach to 100%
You should test the icloud backup on the physical device, simulator environment is not reliable.
