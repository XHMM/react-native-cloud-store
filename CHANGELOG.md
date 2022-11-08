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
