---
title: Install with Expo
sidebar_position: 1
---

**When using Expo, it's necessary to create a [development build](https://docs.expo.dev/develop/development-builds/create-a-build/) and [prebuild](https://docs.expo.dev/workflow/prebuild/) your project.**

## Step 1: Install the package
```bash
npx expo install react-native-cloud-store
```

## Step 2: Plugin configuration
Edit your Expo config file `app.json`/`app.config.js`:
```js
module.exports = () => ({
  // ...
  plugins: [
    [
      "react-native-cloud-store",
      {
        iCloud: {
          kv: {
            enabled: true
          },
          documents: [
            {
              containerId: "iCloud.xxxx",
              enabled: true,
              visible: true,
              visibleName: "myDisplayName"
            },
            {
              containerId: "iCloud.xxxx2",
              enabled: true,
              visible: false
            }
          ]
        }
      }
    ]
  ],
});

```

## Step 3: Prebuild
1. Run the following command to prebuild your project:
  ```shell
  npx expo prebuild
  ```
2. Verify the creation of your iCloud containers. Open the 'ios' folder in XCode, and ensure the containers you've selected are not highlighted in red, indicating they haven't been created. If any container appears in red, simply click the 'Refresh' button (represented by arrow-7) to update.:
     ![check-container-status](/images/check-container-status.png)

## Step 4: Build
You will now need to [build](https://docs.expo.dev/build/setup/#run-a-build) your project.
  ```shell
  eas build --profile development
  ```
