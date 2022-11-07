---
title: ICloud Container(IOS)
sidebar_position: 0
---

## Before
You maybe be frustrated if used wrong path format, should I add file schema or not, should I use relative or absolute path:

- `icloudPath` means you should pass a **full icloud path without schema**, for example:
  - `/path/to/icloud-container/my/file.txt`  ✅
  - `file:///path/to/icloud-container/my/file.txt`  ❌
  - `my/file.txt`  ❌
  - `/my/file.txt`  ❌

  **Why not support relative path anymore?**
  Because one APP may have multiple icloud containers, before we directly passed empty id which means system will choose the first container, now with the support of passing custom container id, we will not know which container you will use.

- `localPath` means you should pass a **full file path with or without schema**, for example:
  - `/path/to/app/documents/my/file.txt`  ✅
  - `file:///path/to/app/documents/my/file.txt`  ✅
  - `/my/file.txt`  ❌



## API
### `isICloudAvailable`
If user disabled your app from accessing icloud drive, or user not logged in with apple id, this will return `false`
```ts
function isICloudAvailable(): Promise<boolean>
```


### `defaultICloudContainerPath`
get the default(the first icloud container selected in xcode settings) container url string, it would be empty string if cannot get, for example: your developer account not create a container, or not choose a container

```ts
import { defaultICloudContainerPath } from 'react-native-cloud-store'
```

### `getICloudURL`
if you want get specific container url, use this method
```ts
function getICloudURL(
  containerIdentifier?: string,
): Promise<string>
```

### `writeFile`
```ts
function writeFile(
    icloudPath: string,
    content: string,
    options: {override: boolean}
): Promise<void>
```

### `readFile`
```ts
function readFile(
  icloudPath: string
): Promise<string> // utf8
```

### `readDir`
```ts
function readDir(
  icloudPath: string
): Promise<string[]>
```

### `createDir`
```ts
function createDir(
  icloudPath: string
): Promise<void>
```

### `moveDir`
```ts
function moveDir(
    icloudPathFrom: string,
    icloudPathTo: string
): Promise<void>
```

### `copy`
copy file or directory
```ts
function copy(
  icloudPathFrom: string,
  icloudPathTo: string,
  options: {override: boolean}
): Promise<void>
```

### `unlink`
remove file or directory
```ts
function unlink(
  icloudPath: string
): Promise<void>
```

### `exist`
check file or directory exists
```ts
function exist(
  icloudPath: string
): Promise<boolean>
```

### `stat`
```ts
function stat(
  icloudPath: string
): Promise<{
  isInICloud?: boolean;
  containerDisplayName?: string;

  isDownloading?: boolean;
  hasCalledDownload?: boolean;
  downloadStatus?: string;
  downloadError?: string;

  isUploaded?: boolean;
  isUploading?: boolean;
  uploadError?: string;

  hasUnresolvedConflicts?: boolean;

  modifyTimestamp?: number;
  createTimestamp?: number;
  name?: string;
  localizedName?: string;
}>
```
### `upload`
upload app's local file to iCloud container, after calling this method, `onICloudDocumentsXxxGathering` events would be triggered.
```ts
function upload(
  localPath: string,
  icloudPath: string
): Promise<void>
```

### `download`
download icloud file to local device, you can only move/copy file after downloading it,  after calling this method, `onICloudDocumentsXxxGathering` events would be triggered.

```ts
function download(
  icloudPath: string,
): Promise<void>
```

## Events
### `onICloudIdentityDidChange`
> rarely used

[APPLE DOC](https://developer.apple.com/documentation/foundation/nsnotification/name/1407629-nsubiquityidentitydidchange): The system generates this notification when the user logs into or out of an iCloud account or enables or disables the syncing of documents and data.  when the user logs into or out of an iCloud account or enables or disables the syncing of documents and data

This event callback data is `{tokenChanged: boolean}`, `tokenChanged` will be `true` if icloud info changed from initial start

### `onICloudDocumentsStartGathering`
This event only be called at the first search phase
### `onICloudDocumentsGathering`
This event only be called at the first search phase
### `onICloudDocumentsFinishGathering`
This event only be called at the first search phase
### `onICloudDocumentsUpdateGathering`
**Use this event to listen upcoming upload/download progress**

**If you download a file that already in local, this event will not be called**, because system no need to download your file, at this time, first-phase related events will be triggered with data. (you can use `downloadStatus` property returned by `stat()` to check if file was in local)
