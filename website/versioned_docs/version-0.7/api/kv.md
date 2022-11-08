---
title: Key-value Storage(IOS)
sidebar_position: 1
---

:::info
[NSUbiquitousKeyValueStore](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore):
- Key-value storage will always be available even if user not logged in icloud.
- Changes of the key-value store object are initially held in memory, then written to disk by the system at appropriate times.

:::

## API

### `kvSync`

[APPLE-DOC](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1415989-synchronize): This method will call [synchronize()](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1415989-synchronize) to explicitly synchronizes in-memory keys and values with those stored on disk.  The only recommended time to call this method is upon app launch, or upon returning to the foreground, to ensure that the in-memory key-value store representation is up-to-date.

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

## Events

### `onICloudKVStoreRemoteChanged`
[APPLE-DOC](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1412267-didchangeexternallynotification): This notification is sent only upon a change received from iCloud; it is not sent when your app sets a value.

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
