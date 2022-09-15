import { NativeModules, Platform, NativeEventEmitter } from 'react-native';

//TODO: auto generate api doc

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

function getConstants(): {
  iCloudContainerPath: string;
} {
  return CloudStore.getConstants();
}

export const iCloudContainerPath = getConstants().iCloudContainerPath

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

export async function isICloudAvailable(): Promise<boolean> {
  return CloudStore.isICloudAvailable();
}

export async function writeFile(
  path: string,
  content: string,
  options?: { override?: boolean }
): Promise<void> {
  return CloudStore.writeFile(path, content, {
    ...options,
  });
}

export async function readFile(path: string): Promise<string> {
  return CloudStore.readFile(path);
}

// if returned filename format is .[file-full-name-with-ext].icloud, means this file is not yet downloaded to local device
export async function readDir(path: string): Promise<string[]> {
  return CloudStore.readDir(path);
}

export async function createDir(path: string): Promise<void> {
  return CloudStore.createDir(path);
}

export async function moveDir(
  pathFrom: string,
  pathTo: string
): Promise<void> {
  return CloudStore.moveDir(pathFrom, pathTo);
}

export async function copy(
  pathFrom: string,
  pathTo: string,
  options?: { override?: boolean }
): Promise<void> {
  return CloudStore.copy(pathFrom, pathTo, {
    ...options,
  });
}

export async function unlink(path: string): Promise<void> {
  return CloudStore.unlink(path);
}

export async function exist(path: string): Promise<boolean> {
  return CloudStore.exist(path);
}

export interface ICloudStat {
  isInICloud?: boolean;
  containerDisplayName?: string;

  isDownloading?: boolean;
  hasCalledDownload?: boolean;
  // https://developer.apple.com/documentation/foundation/urlubiquitousitemdownloadingstatus
  downloadStatus?:
    | 'NSURLUbiquitousItemDownloadingStatusNotDownloaded'
    | 'NSURLUbiquitousItemDownloadingStatusCurrent'
    | 'NSURLUbiquitousItemDownloadingStatusDownloaded';
  downloadError?: string;

  isUploaded?: boolean;
  isUploading?: boolean;
  uploadError?: string;

  hasUnresolvedConflicts?: boolean;

  modifyTimestamp?: number;
  createTimestamp?: number;
  name?: string;
  localizedName?: string;
}
export async function stat(path: string): Promise<ICloudStat> {
  return CloudStore.stat(path);
}

export async function upload(
  fullLocalPath: string,
  path: string
): Promise<void> {
  return CloudStore.upload(fullLocalPath, path);
}

export async function persist(path: string): Promise<void> {
  return CloudStore.persist(path);
}

export type DocumentsGatheringData = {
  info: {
    added: string[];
    changed: string[];
    removed: string[];
  };
  detail: Array<{
    type: 'upload' | 'persist';
    path: string;
    progress: number | null;
    isDir: boolean | null;
  }>;
};
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
