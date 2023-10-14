import { Platform } from 'react-native';
import CloudStore, { eventEmitter } from './module';
import { PathUtils } from './path';

function getConstants(): {
  defaultICloudContainerPath?: string;
} {
  // TODO: android not implement getConstants method, so here just return an empty object
  return Platform.OS === 'ios' ? CloudStore.getConstants() : {};
}

export const defaultICloudContainerPath =
  getConstants().defaultICloudContainerPath;

export async function getDefaultICloudContainerPath(): Promise<
  string | undefined
> {
  return Platform.OS === 'ios'
    ? CloudStore.getDefaultICloudContainerPath()
    : undefined;
}

export async function getICloudURL(
  containerIdentifier?: string
): Promise<string> {
  return CloudStore.getICloudURL(containerIdentifier);
}

export async function isICloudAvailable(): Promise<boolean> {
  return CloudStore.isICloudAvailable();
}

export async function writeFile(
  path: string,
  content: string,
  options?: {
    override?: boolean;
    onProgress?: (data: { progress: number }) => void;
  }
): Promise<void> {
  let canProgress = false;

  if (options?.onProgress) {
    if (!calledGlobalUploadEvent) {
      console.error(
        `You didn't call registerGlobalUploadEvent(), onProgress will not be triggered `
      );
    } else {
      uploadId++;
      uploadId2CallbackDataMap[uploadId] = {
        path: path,
        callback: options.onProgress,
      };
      canProgress = true;
    }
  }

  return CloudStore.writeFile(path, content, {
    ...options,
    id: canProgress ? uploadId.toString() : undefined,
  });
}

export async function readFile(path: string): Promise<string> {
  return CloudStore.readFile(path);
}

export async function readDir(path: string): Promise<string[]> {
  return CloudStore.readDir(path);
}

export async function createDir(path: string): Promise<void> {
  return CloudStore.createDir(path);
}

export async function moveDir(pathFrom: string, pathTo: string): Promise<void> {
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

/**
 * Values that describe the iCloud storage state of a file.
 * https://developer.apple.com/documentation/foundation/urlubiquitousitemdownloadingstatus
 */
export enum DownloadStatus {
  /**
   * A local copy of this item exists and is the most up-to-date version known to the device.
   */
  current = 'NSURLUbiquitousItemDownloadingStatusCurrent',
  /**
   * A local copy of this item exists, but it is stale. The most recent version will be downloaded as soon as possible.
   */
  downloaded = 'NSURLUbiquitousItemDownloadingStatusDownloaded',
  /**
   * This item has not been downloaded yet.
   */
  notDownloaded = 'NSURLUbiquitousItemDownloadingStatusNotDownloaded',
}

export interface ICloudStat {
  isInICloud?: boolean;
  containerDisplayName?: string;
  isDownloading?: boolean;
  hasCalledDownload?: boolean;
  downloadStatus?: DownloadStatus;
  downloadError?: string;
  isUploaded?: boolean;
  isUploading?: boolean;
  uploadError?: string;
  hasUnresolvedConflicts?: boolean;
  modifyTimestamp?: number;
  createTimestamp?: number;
  name?: string;
  localizedName?: string;
  fileSize?: number;
  isDirectory?: boolean;
}

export async function stat(path: string): Promise<ICloudStat> {
  return CloudStore.stat(path);
}

let calledGlobalUploadEvent = false;
let uploadId = 0;
const uploadId2CallbackDataMap: Record<
  string,
  {
    path: string;
    callback: (data: { progress: number }) => void;
  }
> = {};

let calledGlobalDownloadEvent = false;
let downloadId = 0;
const downloadId2CallbackDataMap: Record<
  string,
  {
    path: string;
    callback: (data: { progress: number }) => void;
  }
> = {};

export async function upload(
  localPath: string,
  path: string,
  options?: {
    onProgress: (data: { progress: number }) => void;
  }
): Promise<void> {
  uploadId++;

  if (options?.onProgress) {
    if (!calledGlobalUploadEvent) {
      console.error(
        `You didn't call registerGlobalUploadEvent(), onProgress will not be triggered `
      );
    }
    uploadId2CallbackDataMap[uploadId] = {
      path: path,
      callback: options.onProgress,
    };
  }

  return CloudStore.upload(u(localPath), path, {
    id: uploadId.toString(),
  });
}

export async function download(
  path: string,
  options?: {
    onProgress: (data: { progress: number }) => void;
  }
): Promise<void> {
  downloadId++;

  const pathWithoutDot = PathUtils.iCloudRemoveDotExt(path);

  if (options?.onProgress) {
    if (!calledGlobalDownloadEvent) {
      console.error(
        `You didn't call registerGlobalDownloadEvent(), onProgress will not be triggered `
      );
    }
    downloadId2CallbackDataMap[downloadId] = {
      path: pathWithoutDot,
      callback: options.onProgress,
    };
  }

  return CloudStore.download(path, {
    id: downloadId.toString(),
    pathWithoutDot,
  });
}

// TODO: upload and download logic need to be refactored to be more flexible
export function registerGlobalUploadEvent() {
  if (calledGlobalUploadEvent) {
    return;
  }
  calledGlobalUploadEvent = true;

  function onGatheringCallback(data: DocumentsGatheringData) {
    const callbackData = uploadId2CallbackDataMap[data.id];
    if (!callbackData) return;
    const { path, callback } = callbackData;
    const uploadTarget = data.detail.find(
      (i) => i.type === 'upload' && i.path === path
    );
    if (uploadTarget) {
      const progress = uploadTarget.progress ?? 0;
      if (progress === 100) {
        delete uploadId2CallbackDataMap[uploadId];
      }
      callback({ progress: progress });
    }
  }

  const gatheringListener = onICloudDocumentsGathering(onGatheringCallback);
  const gatheringUpdateListener =
    onICloudDocumentsUpdateGathering(onGatheringCallback);
  const gatheringFinishListener =
    onICloudDocumentsFinishGathering(onGatheringCallback);

  // TODO: directly return the unsubscribe function in next version
  return {
    remove() {
      gatheringListener.remove();
      gatheringUpdateListener.remove();
      gatheringFinishListener.remove();
      calledGlobalUploadEvent = false;
    },
  };
}

export function registerGlobalDownloadEvent() {
  if (calledGlobalDownloadEvent) {
    return;
  }
  calledGlobalDownloadEvent = true;

  function onGatheringCallback(data: DocumentsGatheringData) {
    const callbackData = downloadId2CallbackDataMap[data.id];
    if (!callbackData) return;
    const { path, callback } = callbackData;

    const downloadTarget = data.detail.find(
      (i) => i.type === 'download' && i.path === path
    );
    if (downloadTarget) {
      const progress = downloadTarget.progress ?? 0;
      if (progress === 100) {
        delete downloadId2CallbackDataMap[uploadId];
      }
      callback({ progress: progress });
    }
  }

  const gatheringListener = onICloudDocumentsGathering(onGatheringCallback);
  const gatheringUpdateListener =
    onICloudDocumentsUpdateGathering(onGatheringCallback);
  const gatheringFinishListener =
    onICloudDocumentsFinishGathering(onGatheringCallback);

  // TODO: directly return the unsubscribe function in next version
  return {
    remove() {
      gatheringListener.remove();
      gatheringUpdateListener.remove();
      gatheringFinishListener.remove();
      calledGlobalDownloadEvent = false;
    },
  };
}

export function onICloudIdentityDidChange(
  fn: (data: { tokenChanged: boolean }) => void
) {
  return eventEmitter.addListener('onICloudIdentityDidChange', fn);
}

export type DocumentsGatheringData = {
  id: string;
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

function u(path: string): string {
  let prefix = 'file://';
  if (path.startsWith(prefix)) {
    path = path.slice(prefix.length);
  }
  return path;
}
