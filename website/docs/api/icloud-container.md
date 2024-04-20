---
title: iCloud Container(iOS)
sidebar_position: 0
---

## Typescript Types

### `ICloudPath`
A full icloud path string without schema, for example:
- ✅ `/path/to/icloud-container/my/file.txt`
- ❌ `file:///path/to/icloud-container/my/file.txt`
- ❌ `my/file.txt`
- ❌ `/my/file.txt`

### `LocalPath`
A full file path string with or without schema from your application, for example:
- ✅ `/path/to/app/documents/my/file.txt`
- ✅ `file:///path/to/app/documents/my/file.txt`
- ❌ `/my/file.txt`

## API

### `isICloudAvailable`
Check whether icloud is available. This will return `false` when:
- user disabled your app from accessing icloud drive in system settings
- user did not log in with apple id

```ts
function isICloudAvailable(): Promise<boolean>
```

### `defaultICloudContainerPath`
Get the default icloud container url which is the first container selected in (xcode) settings.

This would be an empty string or undefined if cannot get it, for example:
- the developer did not create a icloud container
- the developer did not choose a icloud container

:::caution
The value of this property was set on app startup and will not change even if user disabled or enabled icloud later while your app is running, you can use `getDefaultICloudContainerPath` to get the always-new data.
:::

```ts
const defaultICloudContainerPath: ICloudPath | undefined
```

### `getDefaultICloudContainerPath`
Get current default container url. This function will always return the newest path or `undefined` if it cannot get it.
```ts
function getDefaultICloudContainerPath(): Promise<ICloudPath | undefined>
```

### `getICloudURL`
Get path from specific container id
```ts
function getICloudURL(
  containerIdentifier?: string,
): Promise<ICloudPath>
```

### `writeFile`
When `onProgress` option provided, make sure you have called `registerGlobalUploadEvent` at the beginning of your app
```ts
function writeFile(
  icloudPath: ICloudPath,
  content: string,
  options: {
    override?: boolean
    isBase64Encoded?: boolean
    onProgress?: (data: {progress: number}) => void
  }
): Promise<void>
```

### `readFile`
Return utf8 string
```ts
function readFile(
  icloudPath: ICloudPath
): Promise<string>
```

### `readDir`
Read files/directories under the provided path

```ts
function readDir(
  icloudPath: ICloudPath
): Promise<ICloudPath[]>
```

### `createDir`
```ts
function createDir(
  icloudPath: ICloudPath
): Promise<void>
```

### `moveDir`
```ts
function moveDir(
  icloudPathFrom: ICloudPath,
  icloudPathTo: ICloudPath
): Promise<void>
```

### `copy`
Copy the file or directory
```ts
function copy(
  icloudPathFrom: ICloudPath,
  icloudPathTo: ICloudPath,
  options: {override: boolean}
): Promise<void>
```

### `unlink`
Delete the file or directory
```ts
function unlink(
  icloudPath: ICloudPath
): Promise<void>
```

### `exist`
Check whether the file or directory exists
```ts
function exist(
  icloudPath: ICloudPath
): Promise<boolean>
```

### `stat`
Get the detailed info of the file/directory
```ts
function stat(
  icloudPath: ICloudPath
): Promise<ICloudStat>

interface ICloudStat {
  isInICloud?: boolean;
  containerDisplayName?: string;
  isDownloading?: boolean;
  hasCalledDownload?: boolean;
  downloadStatus?: DownloadStatus;
  downloadError?: string;
  isUploaded?: boolean;
  isUploading?: boolean;
  uploadError?: string;
  hasUnresolvedConflicts?: boolean;
  modifyTimestamp?: number;
  createTimestamp?: number;
  name?: string;
  localizedName?: string;
  fileSize?: number;
  isDirectory?: boolean;
}
```

### `evictUbiquitousItem`
A wrapper of [evictUbiquitousItem](https://developer.apple.com/documentation/foundation/filemanager/1409696-evictubiquitousitem)

Removes the local copy of the file or directory that’s stored in iCloud. This doesn't delete the file or directory, you should use `unlink` if you want to delete it permanently
```ts
function evictUbiquitousItem(
  path: ICloudPath
): Promise<undefined>
```

### `startDownloadingUbiquitousItem`
A wrapper of [startDownloadingUbiquitousItem](https://developer.apple.com/documentation/foundation/filemanager/1410377-startdownloadingubiquitousitem)

Starts downloading (if necessary) the specified item to the local system.
```ts
function startDownloadingUbiquitousItem(
  path: ICloudPath
): Promise<undefined>
```

### `setUbiquitous`
A wrapper of [setUbiquitous](https://developer.apple.com/documentation/foundation/filemanager/1413989-setubiquitous)

Indicates whether the item at the specified URL should be stored in iCloud.
```ts
function setUbiquitous(
  flag: boolean,
  path: ICloudPath | LocalPath,
  destPath: ICloudPath | LocalPath
): Promise<undefined>
```

### `getUrlForPublishingUbiquitousItem`
A wrapper of [url(forPublishingUbiquitousItemAt..)](https://developer.apple.com/documentation/foundation/filemanager/1411577-url)

Returns a URL that can be emailed to users to allow them to download a copy of a flat file item from iCloud. Your app must have access to the network for this call to succeed.
```ts
function getUrlForPublishingUbiquitousItem(
  path: ICloudPath,
  expirationTimestamp?: number
): Promise<string>
```

### `upload`
Upload the local file from the app to iCloud container,  `icloudPath` should not exist before uploading or it will throw error
:::info
This function will be resolved immediately, if your want to wait until uploaded, you can wrap it with Promise yourself
:::

```ts
function upload(
  localPath: LocalPath,
  icloudPath: ICloudPath,
  options?: {
    onProgress?: (data: {progress: number}) => void
  }
): Promise<void>
```

### `download`
Download file in the icloud.
If you want to put the file in the icloud to your application directories, you must download it and then move/copy the file.
:::info
This function will be resolved immediately, if your want to wait until uploaded, you can wrap it with Promise yourself
:::

```ts
function download(
  // support both `.xx.icloud` and `xx`
  icloudPath: ICloudPath,
  options?: {
    onProgress?: (data: {progress: number}) => void
  }
): Promise<void>
```

## Event Registers

### `registerGlobalUploadEvent`
Call this function at the beginning once to make `onProgress` callback of `upload`/`writeFile` work

```ts
useEffect(() => {
  const uploadEvent = registerGlobalUploadEvent()
  return () => {
    uploadEvent?.remove()
  }
}, [])
```

### `registerGlobalDownloadEvent`
Call this function at the beginning once to make `onProgress` callback of `download` work

```ts
useEffect(() => {
  const downloadEvent = registerGlobalDownloadEvent()
  return () => {
    downloadEvent?.remove()
  }
}, [])
```

### `registerICloudIdentityDidChangeEvent`
Call this function at the beginning once to make `onICloudIdentityDidChange` event work

```ts
useEffect(() => {
  const identityDidChangeEvent = registerICloudIdentityDidChangeEvent()
  return () => {
    identityDidChangeEvent?.remove()
  }
}, [])
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
This event emits when upload/download progress updated.

**If you download a file that already exist locally, this event will not be called**, because system don't need to download cloud file, first-phase related events will be triggered with related data (you can use `downloadStatus` property returned by `stat()` to check if file was in local)

### `onICloudIdentityDidChange`
Rarely used event.
From the [official doc](https://developer.apple.com/documentation/foundation/nsnotification/name/1407629-nsubiquityidentitydidchange): The system generates this notification when the user logs into or out of an iCloud account or enables or disables the syncing of documents and data.  when the user logs into or out of an iCloud account or enables or disables the syncing of documents and data.
