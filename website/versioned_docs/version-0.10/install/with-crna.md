---
title: Install with CRNA
sidebar_position: 0
---

## Step1 - Install
```bash
npm install react-native-cloud-store
```

## Step2 - Link
### For ReactNative 0.60+
Autolink was used, go to step 3 now
### For ReactNative <0.60
```bash
npx react-native link react-native-cloud-store
```

## Step3 - Setup
### For Android
Not supported

### For IOS
1. Run `npx pod-install` in your project root
1. Open your `ios` folder using XCode
1. Because this module was written by `swift`, you need to create an empty swift file and a bridge header file in XCode: `File` -> `New` -> `File` -> Choose 'Swift File' -> Click Next -> save and create file -> XCode will prompt you to create an Objective-C bridging header, select "Create Briding Header"

  :::warning
  Don't delete the created empty swift file!
  :::

  If you are not prompt to create a bridging header file, you can manually create a `xxx.h` file and set header location as below (filename does not matter):
  ![briding-header](/images/bridging-header-settings.png)

1. Next step is add iCloud capability, inside your XCode, select your target -> `Signing & Capabilities` tab -> click "+ Capability" -> search and add "iCloud":
    ![add-ability-in-xcode](/images/add-ability-in-xcode.png)

2. Then scroll to iCloud part: if you use [key-value storage](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore) check `Key-value storage` , if you use [iCloud documents](https://developer.apple.com/documentation/uikit/documents_data_and_pasteboard/synchronizing_documents_in_the_icloud_environment) check `iCloud Documents` and then **select or create a container** and make sure the selected container was not in red which means not created, if color was red, just click arrow-7 to refresh:
   ![check-container-status](/images/check-container-status.png)

3. (Optional Step) If you want to make your iCloud container's `Documents` folder visible to user, open `Info.plist` and change as the following:
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


