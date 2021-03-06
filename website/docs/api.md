---
title: API
sidebar_position: 2
---

## Module Import
```ts
import * as CloudStore from 'react-native-cloud-store'
```

## ICloud Documents API

### `isICloudAvailable`
If user's disabled your app access icloud drive, or user not logged in using apple id, this will return `false`
```ts
function isICloudAvailable(): Promise<boolean>
```

### `writeFile`
```ts
function writeFile(
    // path should relative to iCloudContainerURL,
    // for example: "a/b.txt", "/a/b/c/", ends or starts with '/' not matter
    relativePath: string,
    content: string,
    options: {override: boolean}
): Promise<void>
```

### `readFile`
```ts
function readFile(
    relativePath: string
): Promise<string> // utf8
```

### `readDir`
```ts
function readDir(
    relativePath: string
): Promise<string[]>
```

### `createDir`
```ts
function createDir(
    relativePath: string
): Promise<void>
```

### `moveDir`
```ts
function moveDir(
    relativeFromPath: string,
    relativeToPath: string
): Promise<void>
```

### `copy`
copy file or directory
```ts
function copy(
    srcRelativePath: string,
    destRelativePath: string,
    options: {override: boolean}
): Promise<void>
```

### `unlink`
remove file or directory
```ts
function unlink(
    relativePath: string
): Promise<void>
```

### `exist`
check file or directory exists
```ts
function exist(
    relativePath: string
): Promise<boolean>
```

### `stat`
```ts
function stat(
    relativePath: string
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
### `upload` (IOS 13+)
upload app local file to iCloud container
```ts
function upload(
  // `fullLocalPath` needs to manully specify a schame, such as "file://" to prevent error
  fullLocalPath: string,
  relativePath: string
): Promise<void>
```

### `persist` (IOS 13+)
download/persist cloud file to local device, you can only move/copy file after persisting it
```ts
function persist(
  relativePath: string,
  fullLocalPath: string
): Promise<void>
```

### `onICloudDocumentsStartGathering` (event)
This event only be called at the first search phase
### `onICloudDocumentsGathering` (event)
This event only be called at the first search phase
### `onICloudDocumentsFinishGathering` (event)
This event only be called at the first search phase
### `onICloudDocumentsUpdateGathering` (event)
Use this event to listen upcoming upload/persist progress.

If you persist a file that already downloaded to local, this event will not be called, because system no need to download your file, at this time, results appear in the above first-phase events. (you can use `downloadStatus` property returned by `stat()` to check if file was in local)

## Key-value Storage API
:::info

As [document](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore) said, key-value storage will always be available even if user not logged in icloud.

Changes your app writes to the key-value store object are initially held in memory, then written to disk by the system at appropriate times.

:::

### `kvSync`

This method will call [synchronize()](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1415989-synchronize) to explicitly synchronizes in-memory keys and values with those stored on disk.

As apple doc said, the only recommended time to call this method is upon app launch, or upon returning to the foreground, to ensure that the in-memory key-value store representation is up-to-date.

```ts
function kvSync(): Promise<void>
```

### `kvSetItem`
```ts
function kvSetItem(
    key: string,
    value: string
): Promise<void>
```


### `kvGetItem`
```ts
function kvGetItem(
    key: string,
): Promise<string | undefined>
```


### `kvRemoveItem`
```ts
function kvRemoveItem(
    key: string,
): Promise<void>
```


### `kvGetAllItems`
```ts
function kvGetAllItems(): Promise<Record<string, string>>
```


### `onICloudKVStoreRemoteChanged` (event)

```jsx
const App = () => {
    useEffect(() => {
      const ev = CloudStore.onICloudKVStoreRemoteChange(u => {
        console.log('onICloudKVStoreRemoteChange:', u);
      });
      return () => {
        ev.remove()
      }
    }, [])

    return null
}
```


## Chores API

### `getConstants`

```ts
function getConstants(): {
    // empty string if cannot get, for example your developer account not create a container, or not choose a contanier
    "iCloudContainerPath": string
}
```

