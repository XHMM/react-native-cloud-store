## 0.10.3
- fix: `download` not work correctly
- fix: when `upload`/`download` progress hang if the same prefix file path existed

## 0.10.2
- fix: event not be removed correctly

## 0.10.0
- feat: `onProgress` support for `writeFile`
- feat: add `getDefaultICloudContainerPath()` to solve #13 (thanks to @gutenye)

## 0.9.1(2022-12-18)
- fix: error when running on android due to `getConstants()` call  ([#12](https://github.com/XHMM/react-native-cloud-store/pull/12))

## 0.9.0(2022-12-17)
- feat: `state` will return `fileSize` and `isDirectory` ([#11](https://github.com/XHMM/react-native-cloud-store/pull/11))

## 0.8.1(2022-12-01)
- fix: expo building error for ios ([#7](https://github.com/XHMM/react-native-cloud-store/issues/7))

## 0.8.0(2022-11-15)
- feature: `donwload` and `upload` now support `onProgress`
- add `registerGlobalDownloadEvent` and `registerGlobalUploadEvent`

## 0.7.0(2022-11-09)
- **breaking:** `iCloudContainerPath` renamed to `defaultICloudContainerPath`
- **breaking:** `persist` renamed to `download`
- **breaking:** icloud path do not support relative path now, you must pass an absolute path
- feature: support pass custom container id
- feature: add new `onICloudIdentityDidChange` event

## 0.6.1(2022-09-17)
- fix: not correctly handle local path when using `persist`

## 0.6.0(2022-09-15)
- **breaking:** removed export of `getConstants()`, you can import `iCloudContainerPath` directly
- feature: icloud related apis now support full or relative icloud path
- improvement: document more clear

## 0.5.0
- removed ios13 limitation

## 0.4.x
- some api names and signature changed, check documentation for current versions
- add support for document progress event
- bugs fix

## 0.1.0 (2022-3-13)
- init release
