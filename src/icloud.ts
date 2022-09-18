import CloudStore, { eventEmitter } from './module';
import { u } from './path';

function getConstants(): {
  defaultICloudContainerPath: string;
} {
  return CloudStore.getConstants();
}

export const defaultICloudContainerPath = getConstants().defaultICloudContainerPath

// https://developer.apple.com/documentation/foundation/filemanager/1411653-url
export async function getICloudURL(containerIdentifier?: string): Promise<string> {
  return CloudStore.getICloudURL(containerIdentifier);
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
  localPath: string,
  path: string
): Promise<void> {
  return CloudStore.upload(u(localPath), path);
}

export async function download(path: string): Promise<void> {
  return CloudStore.download(path);
}

export function onICloudIdentityDidChange(
  fn: (data: {tokenChanged: boolean}) => void
) {
  return eventEmitter.addListener('onICloudIdentityDidChange', fn);
}

export type DocumentsGatheringData = {
  info: {
    added: string[];
    changed: string[];
    removed: string[];
  };
  detail: Array<{
    type: 'upload' | 'download';
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
