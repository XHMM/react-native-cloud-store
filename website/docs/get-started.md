---
title: Get Started
sidebar_position: 1
---

## Step1 - Install
With npm:
```bash
npm install react-native-cloud-store
```

With yarn:
```bash
yarn add react-native-cloud-store
```

## Step2 - Link
### For ReactNative 0.60+
Autolink was used, go to step 3 now
### For ReactNative <0.60
```bash
npx react-native link react-native-cloud-store
```

## Step3 - Setup
### For IOS
1. Run `npx pod-install` in your project root
1. Open your `ios` folder using XCode
1. Because this module was written by `swift`, you need to create an empty swift file and bridge header in xcode:
    1. `File` -> `New` -> `File` -> Choose 'Swift File' and Click Next
    1. Select save destination and make sure it's added to your target
    1. Then xcode will prompt if create an Objective-C bridging header, select 'Create Briding Header'
    1. Done.

      :::warning
      Remember don't delete this empty swift file even if it's empty!
      :::

    - If you are not prompt to create briding header file, you can manually create and set header location:
     ![briding-header](/images/bridging-header-settings.png)
1. Next is add icloud capability:
    - Select your target, in the `Singing & Capabilities` tab , click "+ Capability and add iCloud" to add
    - Scroll to iCloud settings part, check `Key-value storage` if you want use [key-value storage](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore), check `iCloud Documents` and select or create a container if you want use [icloud documents](https://developer.apple.com/documentation/uikit/documents_data_and_pasteboard/synchronizing_documents_in_the_icloud_environment)

    - (Optional Step) If you want to make your documents visible to user (appear in icloud dirve):
      1. open `Info.plist` using XCode or other editors
      2. add and ajust the following content:
          ```xml
          <key>NSUbiquitousContainers</key>
          <dict>
              <key>[THIS_IS_CONTAINER_ID_YOU_CHECKED_ABOVE]</key>
              <dict>
                  <key>NSUbiquitousContainerIsDocumentScopePublic</key>
                  <true/>
                  <key>NSUbiquitousContainerName</key>
                  <string>[THIS_IS_THE_NAME_SHOWED_IN_ICLOUD_DRIVE]</string>
              </dict>
          </dict>
          ```


### For Android
Not supported
