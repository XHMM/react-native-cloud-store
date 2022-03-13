import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-cloud-store' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

const CloudStore = NativeModules.CloudStoreModule;

if (Platform.OS === 'ios' && !CloudStore) {
  throw new Error(LINKING_ERROR);
}

export function getConstants(): {
  icloudContainerPath: string;
} {
  return CloudStore.getConstants();
}

export async function isICloudAvailable(): Promise<boolean> {
  return CloudStore.isICloudAvailable();
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

export async function copyFile(
  srURIOrRelativePath: string,
  destRelativePath: string,
  options?: { override?: boolean }
): Promise<void> {
  return CloudStore.copyFile(srURIOrRelativePath, destRelativePath, {
    ...options,
  });
}

export async function fileOrDirExists(relativePath: string): Promise<boolean> {
  return CloudStore.fileOrDirExists(relativePath);
}

export async function readFile(relativePath: string): Promise<string> {
  return CloudStore.readFile(relativePath);
}

export async function readDir(relativePath: string): Promise<string[]> {
  return CloudStore.readDir(relativePath);
}

export async function createDir(relativePath: string): Promise<string[]> {
  return CloudStore.createDir(relativePath);
}

export async function moveDir(
  relativeFromPath: string,
  relativeToPath: string
): Promise<void> {
  return CloudStore.moveDir(relativeFromPath, relativeToPath);
}

export async function unlink(relativePath: string): Promise<void> {
  return CloudStore.unlink(relativePath);
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

export type OnICloudKVStoreRemoteChangedHandler = (userInfo: any) => void;
