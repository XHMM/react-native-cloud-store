---
title: Expo
sidebar_position: 0
---
When your project was created using expo, you should follow this instruction

**If you want to use this package with expo ,you need [prebuild](https://docs.expo.dev/workflow/expo-cli/#expo-prebuild) your project, and you will lose features provided by Expo Go**

## Step1 - Install
With npm:
```bash
npm install react-native-cloud-store
```

With yarn:
```bash
yarn add react-native-cloud-store
```

## Step2
Edit expo config file `app.json`/`app.config.js`:
```js
module.exports = () => ({
  // ...
  plugins: [
    [
      "react-native-cloud-store",
      {
        iCloud: {
          kv: {
            enabled: true,
          },
          documents: {
            containerId: `iCloud.xxxx`,
            enabled: true,
            visible: true,
            visibleName: `myDisplayName`,
          },
        },
      },
    ],
  ],
});
```

## Build and config
1. run the following command to prebuild your project:
  ```shell
  expo prebuild
  ```
2. open your `ios` folder using XCode and add iCloud capability:
   - Go to [developer account website](https://developer.apple.com/account/resources/identifiers/list) and make sure your app identifier enabled iCloud:
     ![enable-icloud-in-identifier](/images/enable-icloud-in-identifier.png)
   - Back to XCode, select your target -> `Signing & Capabilities` tab -> click "+ Capability" -> search and add "iCloud" just live below:
     ![add-ability-in-xcode](/images/add-ability-in-xcode.png)

     then scroll to iCloud settings part: if you use [key-value storage](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore) check `Key-value storage` , if you use [iCloud documents](https://developer.apple.com/documentation/uikit/documents_data_and_pasteboard/synchronizing_documents_in_the_icloud_environment) check `iCloud Documents` and then **select or create a container**

