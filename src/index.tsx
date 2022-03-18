import { NativeModules, Platform, NativeEventEmitter } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-cloud-store' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

const CloudStore = NativeModules.CloudStoreModule;

if (Platform.OS === 'ios' && !CloudStore) {
  throw new Error(LINKING_ERROR);
}
const eventEmitter = new NativeEventEmitter(CloudStore);

export function getConstants(): {
  icloudContainerPath: string;
} {
  return CloudStore.getConstants();
}

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

// doc: https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/1433687-change_reason_values
export enum KVStoreChangedReason {
  NSUbiquitousKeyValueStoreServerChange,
  NSUbiquitousKeyValueStoreInitialSyncChange,
  NSUbiquitousKeyValueStoreQuotaViolationChange,
  NSUbiquitousKeyValueStoreAccountChange,
}

interface KVStoreChangedData {
  reason: KVStoreChangedReason;
  changedKeys: string[];
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

export async function isICloudAvailable(): Promise<boolean> {
  return CloudStore.isICloudAvailable();
}

interface ICloudFile {
  content: string;
  downloadStatus: string;
}

export async function writeFile(
  relativePath: string,
  content: string,
  options?: { override?: boolean }
): Promise<void> {
  return CloudStore.writeFile(relativePath, content, {
    ...options,
  });
}

export async function readFile(relativePath: string): Promise<ICloudFile> {
  return CloudStore.readFile(relativePath);
}

// if filename format is .[file-full-name-with-ext].icloud, means this file is not yet downloaded to local device
export async function readDir(relativePath: string): Promise<string[]> {
  return CloudStore.readDir(relativePath);
}

export async function createDir(relativePath: string): Promise<void> {
  return CloudStore.createDir(relativePath);
}

export async function moveDir(
  relativeFromPath: string,
  relativeToPath: string
): Promise<void> {
  return CloudStore.moveDir(relativeFromPath, relativeToPath);
}

export async function copy(
  srcRelativePath: string,
  destRelativePath: string,
  options?: { override?: boolean }
): Promise<void> {
  return CloudStore.copy(srcRelativePath, destRelativePath, {
    ...options,
  });
}

export async function unlink(relativePath: string): Promise<void> {
  return CloudStore.unlink(relativePath);
}

export async function exist(relativePath: string): Promise<boolean> {
  return CloudStore.exist(relativePath);
}

export async function upload(
  fullLocalPath: string,
  relativePath: string
): Promise<void> {
  return CloudStore.upload(fullLocalPath, relativePath);
}

export async function persist(relativePath: string): Promise<void> {
  return CloudStore.persist(relativePath);
}

type DocumentsGatheringData = Array<{
  type: 'upload' | 'persist';
  iCloudFileRelativePath: string;
  progress: number;
}>;
type DocumentsGatheringEventHandler = (data: DocumentsGatheringData) => void;
export function onICloudDocumentsStartGathering(
  fn: DocumentsGatheringEventHandler
) {
  return eventEmitter.addListener(
    'onICloudDocumentsStartGathering',
    (nativeData: any) => {
      fn(nativeData);
    }
  );
}

export function onICloudDocumentsGathering(fn: DocumentsGatheringEventHandler) {
  return eventEmitter.addListener('onICloudDocumentsGathering', fn);
}

export function onICloudDocumentsFinishGathering(
  fn: DocumentsGatheringEventHandler
) {
  return eventEmitter.addListener('onICloudDocumentsFinishGathering', fn);
}

export function onICloudDocumentsUpdateGathering(
  fn: DocumentsGatheringEventHandler
) {
  return eventEmitter.addListener('onICloudDocumentsUpdateGathering', fn);
}
