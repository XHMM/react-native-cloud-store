---
title: Key-value Storage(iOS)
sidebar_position: 1
---

:::info
You can check out the [official doc](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore) for detailed instructions.
:::

## API

### `kvSync`

From [official doc](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1415989-synchronize): This method will call [synchronize()](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1415989-synchronize) to explicitly synchronizes in-memory keys and values with those stored on disk.  The only recommended time to call this method is upon app launch, or upon returning to the foreground, to ensure that the in-memory key-value store representation is up-to-date.

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

## Event Registers

### `registerKVStoreRemoteChangedEvent`
Call this function at the beginning once to make `onKVStoreRemoteChanged` work

## Events

### `onKVStoreRemoteChanged`
From [official doc](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1412267-didchangeexternallynotification): This notification is sent only upon a change received from iCloud; it is not sent when your app sets a value.
