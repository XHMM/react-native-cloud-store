---
title: Trouble Shooting
sidebar_position: 3
---

## Why my folder and files not appear/visible in iCloud drive folder?
1. make sure you updated `NSUbiquitousContainers` in `Info.plist` as described in [Get Started](https://react-native-cloud-store.vercel.app/docs/get-started),
2. make sure your path passed to API includes 'Documents' part, for example should be '/path/to/icloud/container/**Documents**/myCustomContent' instead '/path/to/icloud/container/myCustomContent'
3. if above are ok, try to bump your build version in XCode/Info.plist, and rebuild

## How to check if file synced to icloud drive successfully?
When using 'icloud documents', you cannot get if your file has finally synced to icloud drive, backup strategy is controlled by system, but local data will not be removed even if user uninstalled your app, system will back up them finally, unless user manually delete them before system's backup done.

In other words, icloud-document apis also work when user's network unavailable, system will automatically back up data when network recovered.
