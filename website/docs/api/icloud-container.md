---
title: ICloud Container(IOS)
sidebar_position: 0
---

## Before
You maybe be frustrated if used wrong path format: passing file schema or not, relative or absolute path:

- `localPath`: means you should pass a **full file path with or without schema**, for example:
  - `file:///path/to/app/documents/my/file.txt`  ok
  - `/path/to/app/documents/my/file.txt`  ok
  - `/my/file.txt`  not ok


- `icloudPath`: means you can pass a full icloud path or relative icloud file path(ends or starts with '/' not matter), for example:
  - `/path/to/icloud-container/my/file.txt`  ok
  - `my/file.txt`  ok
  - `/my/file.txt`  ok


## API
### `isICloudAvailable`
If user disabled your app from accessing icloud drive, or user not logged in with apple id, this will return `false`
```ts
function isICloudAvailable(): Promise<boolean>
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

### `persist`
download/persist icloud file(these files named with format `.fileName.icloud`) to local device, you can only move/copy file after persisting it,  after calling this method, `onICloudDocumentsXxxGathering` events would be triggered.
```ts
function persist(
  icloudPath: string,
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
**Use this event to listen upcoming upload/persist progress**

**If you persist a file that already downloaded to local, this event will not be called**, because system no need to download your file, at this time, first-phase related events will be triggered with data. (you can use `downloadStatus` property returned by `stat()` to check if file was in local)
