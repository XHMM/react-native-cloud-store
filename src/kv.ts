import CloudStore, { eventEmitter } from './module';

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
 * https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1433687-change_reason_values
 */
export enum KVStoreChangedReason {
  NSUbiquitousKeyValueStoreServerChange,
  NSUbiquitousKeyValueStoreInitialSyncChange,
  NSUbiquitousKeyValueStoreQuotaViolationChange,
  NSUbiquitousKeyValueStoreAccountChange,
}

interface KVStoreChangedData {
  reason: KVStoreChangedReason;
  changedKeys?: string[];
}

export function onICloudKVStoreRemoteChange(
  fn: (data: KVStoreChangedData) => void
) {
  return eventEmitter.addListener(
    'onICloudKVStoreRemoteChanged',
    (nativeData: any) => {
      fn({
        reason: nativeData.NSUbiquitousKeyValueStoreChangeReasonKey,
        changedKeys: nativeData.NSUbiquitousKeyValueStoreChangedKeysKey,
      });
    }
  );
}
