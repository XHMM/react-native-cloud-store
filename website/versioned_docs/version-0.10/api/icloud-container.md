---
title: iCloud Container(IOS)
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
Get the default(the first icloud container selected in xcode settings) container url string.

This would be empty string if cannot get, for example: your developer account not create a container, or not choose a container

**warning**: this property was set on app startup and will not change even if user disabled or enabled icloud, you can use `getDefaultICloudContainerPath()` to get the always new path.

```ts
import { defaultICloudContainerPath } from 'react-native-cloud-store'
```

### `getDefaultICloudContainerPath`
Get current default container url, this function will always return newest path.

This would be `undefined` if cannot get.
```ts
function getDefaultICloudContainerPath(): Promise<string | undefined>
```

### `getICloudURL`
Get path from the specific container id
```ts
function getICloudURL(
  containerIdentifier?: string,
): Promise<string>
```

### `writeFile`
When `onProgress` option provided, you must manually call [`registerglobaluploadevent`](#registerglobaluploadevent), also, this function behaves just like [`upload`](#upload)
```ts
function writeFile(
  icloudPath: string,
  content: string,
  options: {
    override?: boolean
    onProgress?: (data: {progress: number}) => void
  }
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
Copy file or directory
```ts
function copy(
  icloudPathFrom: string,
  icloudPathTo: string,
  options: {override: boolean}
): Promise<void>
```

### `unlink`
Remove file or directory
```ts
function unlink(
  icloudPath: string
): Promise<void>
```

### `exist`
Check file or directory exists
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

### `registerGlobalUploadEvent`
**You must call this function globally, or `onProgress` callback of `upload`/`writeFile` will not be triggered**

```ts
import { useEffect } from 'react';

useEffect(() => {
  const uploadEvent = registerGlobalUploadEvent()
  return () => {
    uploadEvent?.remove()
  }
}, [])
```

### `registerGlobalDownloadEvent`
**You must call this function globally, or `onProgress` callback of `download` will not be triggered**

```ts
import { useEffect } from 'react';

useEffect(() => {
  const downloadEvent = registerGlobalDownloadEvent()
  return () => {
    downloadEvent?.remove()
  }
}, [])
```

### `upload`
Upload app's local file to iCloud container,  `icloudPath` should not exist before uploading, or it will throw error
:::info
This function will be resolved immediately, if your want to wait until uploaded, you can wrap it with Promise yourself
:::

```ts
function upload(
  localPath: string,
  icloudPath: string,
  options?: {
    onProgress?: (data: {progress: number}) => void
  }
): Promise<void>
```


### `download`
Download icloud file to local device, you can only move/copy file after downloading it
:::info
This function will be resolved immediately, if your want to wait until uploaded, you can wrap it with Promise yourself
:::

```ts
function download(
  icloudPath: string,
  options?: {
    onProgress?: (data: {progress: number}) => void
  }
): Promise<void>
```

## Events

### `onICloudDocumentsStartGathering`
This event only be called at the first search phase
### `onICloudDocumentsGathering`
This event only be called at the first search phase
### `onICloudDocumentsFinishGathering`
This event only be called at the first search phase
### `onICloudDocumentsUpdateGathering`
:::info
`download` and `uplaod` have supported `onProgress`, so this event is not needed if you don't have special needs
:::
Use this event to listen upcoming upload/download progress

**If you download a file that already exist locally, this event will not be called**, because system don't need to download cloud file, first-phase related events will be triggered with related data (you can use `downloadStatus` property returned by `stat()` to check if file was in local)

### `onICloudIdentityDidChange`
> Rarely used

[APPLE DOC](https://developer.apple.com/documentation/foundation/nsnotification/name/1407629-nsubiquityidentitydidchange): The system generates this notification when the user logs into or out of an iCloud account or enables or disables the syncing of documents and data.  when the user logs into or out of an iCloud account or enables or disables the syncing of documents and data

This event callback data is `{tokenChanged: boolean}`, `tokenChanged` will be `true` if icloud info changed from initial start
