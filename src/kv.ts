import CloudStore, { eventEmitter } from './module';

/**
 * From [official doc](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1415989-synchronize): This method will call [synchronize()](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1415989-synchronize) to explicitly synchronizes in-memory keys and values with those stored on disk. The only recommended time to call this method is upon app launch, or upon returning to the foreground, to ensure that the in-memory key-value store representation is up-to-date.
 */
export async function kvSync(): Promise<void> {
  return CloudStore.kvSync();
}

export async function kvSetItem(key: string, value: string): Promise<void> {
  return CloudStore.kvSetItem(key, value);
}

export async function kvGetItem(key: string): Promise<string | undefined> {
  return CloudStore.kvGetItem(key);
}

export async function kvRemoveItem(key: string): Promise<void> {
  return CloudStore.kvRemoveItem(key);
}

export async function kvGetAllItems(): Promise<Record<string, string>> {
  return CloudStore.kvGetAllItems();
}

/**
 * Change reasons, see [official doc](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1433687-change_reason_values) for details
 */
export enum KVStoreChangedReason {
  NSUbiquitousKeyValueStoreServerChange = 0,
  NSUbiquitousKeyValueStoreInitialSyncChange,
  NSUbiquitousKeyValueStoreQuotaViolationChange,
  NSUbiquitousKeyValueStoreAccountChange,
}

let calledKVStoreRemoteChangedEvent = false;

/**
 * Call this function at the beginning once to make `onKVStoreRemoteChanged` work
 */
export function registerKVStoreRemoteChangedEvent() {
  if (calledKVStoreRemoteChangedEvent) {
    return;
  }

  calledKVStoreRemoteChangedEvent = true;
  CloudStore.listenKvDidChangeExternallyNotification();

  return {
    remove() {
      CloudStore.unlistenKvDidChangeExternallyNotification();
      calledKVStoreRemoteChangedEvent = false;
    },
  };
}

export interface KVStoreChangedData {
  reason: KVStoreChangedReason;
  changedKeys?: string[];
}

/**
 * From [official doc](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1412267-didchangeexternallynotification): This notification is sent only upon a change received from iCloud; it is not sent when your app sets a value.
 */
export function onKVStoreRemoteChanged(fn: (data: KVStoreChangedData) => void) {
  if (!calledKVStoreRemoteChangedEvent) {
    console.error(
      `You didn't call registerKVStoreRemoteChangedEvent(), this listener will not trigger`
    );
  }

  return eventEmitter.addListener(
    'onKVStoreRemoteChanged',
    (nativeData: any) => {
      fn({
        reason: nativeData.NSUbiquitousKeyValueStoreChangeReasonKey,
        changedKeys: nativeData.NSUbiquitousKeyValueStoreChangedKeysKey,
      });
    }
  );
}
