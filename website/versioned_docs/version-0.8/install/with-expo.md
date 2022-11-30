---
title: Install with Expo
sidebar_position: 1
---

**You need to [prebuild](https://docs.expo.dev/workflow/expo-cli/#expo-prebuild) your project when using with expo**

## Step1
```bash
npm install react-native-cloud-store
```

## Step2
Edit your expo config file `app.json`/`app.config.js`:
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
          documents: [
            {
              containerId: `iCloud.xxxx`,
              enabled: true,
              visible: true,
              visibleName: `myDisplayName`,
            },
            {
              containerId: `iCloud.xxxx2`,
              enabled: true,
              visible: false
            }
          ],
          environment: 'Production' // 'Production' or 'Development'
        },
      },
    ],
  ],
});
```

- You need to set `environment` if occurred [this error](https://github.com/XHMM/react-native-cloud-store/issues/7) when building

## Step3
1. Run the following command to prebuild your project:
  ```shell
  expo prebuild
  ```
2. At the first time, you need to make sure iCloud containers were created, so now open your `ios` folder using XCode, make sure the selected containers were not in red color which means not created yet, if color was red, just click arrow-7 to refresh:
     ![check-container-status](/images/check-container-status.png)

