#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(CloudStoreModule, RCTEventEmitter)

// kv
RCT_EXTERN_METHOD(kvSync :(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(kvSetItem: (NSString)key and: (NSString)value resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(kvGetItem :(NSString)key resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(kvRemoveItem :(NSString)key resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(kvGetAllItems :(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(listenKvDidChangeExternallyNotification :(RCTPromiseResolveBlock)resolve                                     rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(unlistenKvDidChangeExternallyNotification :(RCTPromiseResolveBlock)resolve                                     rejecter: (RCTPromiseRejectBlock)reject)

// icloud chores
RCT_EXTERN_METHOD(getICloudURL :(NSString)containerIdentifier resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(isICloudAvailable :(RCTPromiseResolveBlock)resolve                                     rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getDefaultICloudContainerPath :(RCTPromiseResolveBlock)resolve                                     rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(listenICloudNSUbiquityIdentityDidChange :(RCTPromiseResolveBlock)resolve                                     rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(unlistenICloudNSUbiquityIdentityDidChange :(RCTPromiseResolveBlock)resolve                                     rejecter: (RCTPromiseRejectBlock)reject)

// icloud file
RCT_EXTERN_METHOD(writeFile: (NSString)path withContent:(NSString)content with:(NSDictionary)options resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(readFile: (NSString)path resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
// icloud dir
RCT_EXTERN_METHOD(readDir: (NSString)path resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(createDir: (NSString)path resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(moveDir :(NSString)pathFrom to:(NSString)pathTo resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// icloud file/dir
RCT_EXTERN_METHOD(copy: (NSString)pathFrom to:(NSString)pathTo with:(NSDictionary)options resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(unlink: (NSString)path resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(exist: (NSString)path resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(stat: (NSString)path resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(evictUbiquitousItem: (NSString)path resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(startDownloadingUbiquitousItem: (NSString)path resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(setUbiquitous: (BOOL)flag itemAt:(NSString)path destination:(NSString)destPath resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getUrlForPublishingUbiquitousItem: (NSString)path expiration:(nonnull NSNumber)expirationTS resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(upload :(NSString)fullLocalPath to:(NSString)path with:(NSDictionary)options resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(download :(NSString)path with:(NSDictionary)options resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)

@end
