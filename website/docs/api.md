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
    // path should relative to icloudContainerURL,
    // for example: "a/b.txt", "/a/b/c/", ends or starts with '/' not matter
    relativePath: string,
    content: string,
    options: {override: boolean}
): Promise<void>
```

### `copyFile`
```ts
function copyFile(
    // supported format:
    //  - path relative to icloudContainerURL
    //  - file:///xx/yy
    srcURIOrRelativePath: string,
    destRelativePath: string,
    options: {override: boolean}
): Promise<void>
```

### `fileOrDirExists`
```ts
function fileOrDirExists(
    relativePath: string
): Promise<boolean>
```

### `readFile`
```ts
function readFile(
    relativePath: string
): Promise<string>  // utf8 format
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

### `unlink`
remove file or directory
```ts
function unlink(
    relativePath: string
): Promise<void>
```

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
import { NativeEventEmitter } from 'react-native';
import { useEffect } from "react";
import * as CloudStore from 'react-native-cloud-store'

const App = () => {
    useEffect(() => {
        const event = new NativeEventEmitter(CloudStore);
        event.addListener('onICloudKVStoreRemoteChanged', (userInfo) => {
           console.log(userInfo.changedKeys)
        });

        return () => {
            event.remove()
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
    "icloudContainerPath": string
}
```

