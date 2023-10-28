import { Platform } from 'react-native';
import CloudStore, { eventEmitter } from './module';
import { PathUtils } from './path';

function getConstants(): {
  defaultICloudContainerPath?: string;
} {
  return Platform.OS === 'ios' ? CloudStore.getConstants() : {};
}

/**
 * A full icloud path string without schema, for example:
 * - ✅ `/path/to/icloud-container/my/file.txt`
 * - ❌ `file:///path/to/icloud-container/my/file.txt`
 * - ❌ `my/file.txt`
 * - ❌ `/my/file.txt`
 */
export type ICloudPath = string;
/**
 * A full file path string with or without schema, for example:
 * - ✅ `/path/to/app/documents/my/file.txt`
 * - ✅ `file:///path/to/app/documents/my/file.txt`
 * - ❌ `/my/file.txt`
 */
export type LocalPath = string;

/**
 *  Check whether icloud is available. This will return `false` when:
 *  - user disabled your app from accessing icloud drive in system settings
 *  - user did not log in with apple id
 *
 * @group Group Base
 */
export async function isICloudAvailable(): Promise<boolean> {
  return CloudStore.isICloudAvailable();
}

/**
 * Get the default icloud container url which is the first container selected in (xcode) settings.
 *
 * This would be an empty string or undefined if cannot get it, for example:
 *  - the developer did not create a icloud container
 *  - the developer did not choose a icloud container
 *
 * :::caution
 * The value of this property was set on app startup and will not change even if user disabled or enabled icloud later while your app was running, you can use {@link getDefaultICloudContainerPath} to get the always-new data.
 * :::
 * @category iCloud
 */
export const defaultICloudContainerPath: ICloudPath | undefined =
  getConstants().defaultICloudContainerPath;

/**
 * Get current default container url. This function will always return the newest path or `undefined` if it cannot get it.
 *
 * @category Base
 */
export async function getDefaultICloudContainerPath(): Promise<
  ICloudPath | undefined
> {
  return Platform.OS === 'ios'
    ? CloudStore.getDefaultICloudContainerPath()
    : undefined;
}

/**
 * Get path from specific container id
 *
 * @category Base
 */
export async function getICloudURL(
  containerIdentifier?: string
): Promise<ICloudPath> {
  return CloudStore.getICloudURL(containerIdentifier);
}

/**
 * When `onProgress` option provided, make sure you have called {@link registerGlobalUploadEvent} at the beginning of your app
 * @group Group File
 */
export async function writeFile(
  path: ICloudPath,
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

/**
 * Return utf8 string
 * @category File
 */
export async function readFile(path: ICloudPath): Promise<string> {
  return CloudStore.readFile(path);
}

/**
 * Read files/directories under the provided path
 * @category Directory
 */
export async function readDir(path: ICloudPath): Promise<ICloudPath[]> {
  return CloudStore.readDir(path);
}

/**
 *
 * @category Directory
 */
export async function createDir(path: ICloudPath): Promise<void> {
  return CloudStore.createDir(path);
}

/**
 *
 * @category Directory
 */
export async function moveDir(
  pathFrom: ICloudPath,
  pathTo: ICloudPath
): Promise<void> {
  return CloudStore.moveDir(pathFrom, pathTo);
}

/**
 * Copy the file or directory

 * @category File / Directory
 */
export async function copy(
  pathFrom: ICloudPath,
  pathTo: ICloudPath,
  options?: { override?: boolean }
): Promise<void> {
  return CloudStore.copy(pathFrom, pathTo, {
    ...options,
  });
}

/**
 * Delete the file or directory. deleting items from iCloud can’t be undone. Once deleted, the item is gone forever.
 * @category File / Directory
 */
export async function unlink(path: ICloudPath): Promise<void> {
  return CloudStore.unlink(path);
}

/**
 * Check whether the file or directory exists
 * @category File / Directory
 */
export async function exist(path: ICloudPath): Promise<boolean> {
  return CloudStore.exist(path);
}

/**
 * Values that describe the iCloud storage state of a file. ([official doc](https://developer.apple.com/documentation/foundation/urlubiquitousitemdownloadingstatus))
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

/**
 * File/Directory detailed info
 */
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

/**
 * Get the detailed info of the file/directory
 * @param path
 * @category File / Directory
 */
export async function stat(path: ICloudPath): Promise<ICloudStat> {
  return CloudStore.stat(path);
}

/**
 * A wrapper of [evictUbiquitousItem](https://developer.apple.com/documentation/foundation/filemanager/1409696-evictubiquitousitem)
 *
 * Removes the local copy of the file or directory that’s stored in iCloud. This doesn't delete the file or directory, you should use {@link unlink} if you want to delete it permanently
 */
export async function evictUbiquitousItem(
  path: ICloudPath
): Promise<undefined> {
  return CloudStore.evictUbiquitousItem(path);
}

/**
 * A wrapper of [startDownloadingUbiquitousItem](https://developer.apple.com/documentation/foundation/filemanager/1410377-startdownloadingubiquitousitem)
 *
 * Starts downloading (if necessary) the specified item to the local system.
 */
export async function startDownloadingUbiquitousItem(
  path: ICloudPath
): Promise<undefined> {
  return CloudStore.startDownloadingUbiquitousItem(path);
}

/**
 * A wrapper of [setUbiquitous](https://developer.apple.com/documentation/foundation/filemanager/1413989-setubiquitous)
 *
 * Indicates whether the item at the specified URL should be stored in iCloud.
 *
 * @param flag - `true` to move the item to iCloud or `false` to remove it from iCloud (if it is there currently).
 * @param path - The path of the item (file or directory) that you want to store in iCloud.
 * @param destPath - If moving a file into iCloud, it's the location in iCloud at which to store the file or directory. If moving a file out of iCloud, it's the location on the local device.
 */
export async function setUbiquitous(
  flag: boolean,
  path: ICloudPath | LocalPath,
  destPath: ICloudPath | LocalPath
): Promise<undefined> {
  return CloudStore.setUbiquitous(flag, path, destPath);
}

/**
 * A wrapper of [url(forPublishingUbiquitousItemAt..)](https://developer.apple.com/documentation/foundation/filemanager/1411577-url)
 *
 * Returns a URL that can be emailed to users to allow them to download a copy of a flat file item from iCloud. Your app must have access to the network for this call to succeed.
 *
 * @param path - The path in the cloud that you want to share. The file at the specified path must already be uploaded to iCloud when you call this method.
 * @param expirationTimestamp - Timestamp of the expiration date
 */
export async function getUrlForPublishingUbiquitousItem(
  path: ICloudPath,
  expirationTimestamp?: number
): Promise<string> {
  return CloudStore.getUrlForPublishingUbiquitousItem(
    path,
    expirationTimestamp ?? -1
  );
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

/**
 * Upload the local file from the app to iCloud container,  `icloudPath` should not exist before uploading or it will throw error
 * :::info
 * This function will be resolved immediately, if your want to wait until uploaded, you can wrap it with `Promise` yourself
 * :::
 */
export async function upload(
  localPath: LocalPath,
  path: ICloudPath,
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

/**
 * Download file in the icloud.
 * If you want to put the file in the icloud to your application directories, you must download it and then move/copy the file.
 * :::info
 * This function will be resolved immediately, if your want to wait until uploaded, you can wrap it with Promise yourself
 * :::
 * @param path
 * @param options
 */
export async function download(
  path: ICloudPath,
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
/**
 * Call this function at the beginning once to make `onProgress` callback of `upload`/`writeFile` work
 */
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

  return {
    remove() {
      gatheringListener.remove();
      gatheringUpdateListener.remove();
      gatheringFinishListener.remove();
      calledGlobalUploadEvent = false;
    },
  };
}

/**
 * Call this function at the beginning once to make `onProgress` callback of `download` work
 */
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

  return {
    remove() {
      gatheringListener.remove();
      gatheringUpdateListener.remove();
      gatheringFinishListener.remove();
      calledGlobalDownloadEvent = false;
    },
  };
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
export type DocumentsGatheringEventHandler = (
  data: DocumentsGatheringData
) => void;

/**
 * This event only emits at the first search phase
 * @category Events
 */
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

/**
 * This event only emits at the first search phase
 * @param fn
 * @category Events
 */
export function onICloudDocumentsGathering(fn: DocumentsGatheringEventHandler) {
  return eventEmitter.addListener('onICloudDocumentsGathering', fn);
}

/**
 * This event only emits at the first search phase
 * @category Events
 */
export function onICloudDocumentsFinishGathering(
  fn: DocumentsGatheringEventHandler
) {
  return eventEmitter.addListener('onICloudDocumentsFinishGathering', fn);
}

/**
 * This event emits when upload/download progress updated.
 * :::info
 * `download` and `upload` have supported `onProgress`, so this event is not needed if you don't have special needs
 * :::
 *
 * @category Events
 */
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

let calledIdentityDidChangeEvent = false;

/**
 * Call this function at the beginning once to make `onICloudIdentityDidChange` event work
 */
export function registerICloudIdentityDidChangeEvent() {
  if (calledIdentityDidChangeEvent) {
    return;
  }

  calledIdentityDidChangeEvent = true;
  CloudStore.listenICloudNSUbiquityIdentityDidChange();

  return {
    remove() {
      CloudStore.unlistenICloudNSUbiquityIdentityDidChange();
      calledIdentityDidChangeEvent = false;
    },
  };
}

/**
 * Rarely used event.
 * From the [official doc](https://developer.apple.com/documentation/foundation/nsnotification/name/1407629-nsubiquityidentitydidchange): The system generates this notification when the user logs into or out of an iCloud account or enables or disables the syncing of documents and data.  when the user logs into or out of an iCloud account or enables or disables the syncing of documents and data.
 *
 * @category Events
 */
export function onICloudIdentityDidChange(
  fn: (data: { tokenChanged: boolean }) => void
) {
  if (!calledIdentityDidChangeEvent) {
    console.error(
      `You didn't call registerICloudIdentityDidChangeEvent(), this listener will not trigger`
    );
  }

  return eventEmitter.addListener('onICloudIdentityDidChange', fn);
}
