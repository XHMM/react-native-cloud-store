import { NativeEventEmitter, NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-cloud-store' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

const CloudStore = NativeModules.CloudStoreModule;

if (Platform.OS === 'ios' && !CloudStore) {
  throw new Error(LINKING_ERROR);
}
export default CloudStore;
export const eventEmitter = new NativeEventEmitter(CloudStore);
