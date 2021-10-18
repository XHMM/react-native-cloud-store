import Foundation

extension String {
  func rmPrefix(_ prefix: String) -> String {
    guard self.hasPrefix(prefix) else { return self }
    return String(self.dropFirst(prefix.count))
  }
}

@objc(CloudStoreModule)
class CloudStoreModule : RCTEventEmitter {
  var icloudURL: URL? {
    FileManager.default.url(forUbiquityContainerIdentifier: nil)
  }

  override init() {
    super.init()

    NotificationCenter.default.addObserver(self, selector: #selector(onICloudKVStoreRemoteChanged(notification:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
  }

  @objc func onICloudKVStoreRemoteChanged(notification:Notification) {
    sendEvent(withName: "onICloudKVStoreRemoteChanged", body: notification.userInfo)
  }

  override func supportedEvents() -> [String]! {
      return ["onICloudKVStoreRemoteChanged"]
  }


  override func constantsToExport() -> [AnyHashable : Any] {
    return ["icloudContainerPath": icloudURL?.path ?? ""]
  }

  // make sure icloud exists before doing extra things
  private func _assertICloud(ifNil reject: RCTPromiseRejectBlock) -> Bool {
    guard icloudURL != nil else {
      reject("ERR_PATH_NOT_EXIST", "ICloud container path not exists, check your [XCode -> Singing & Capability -> iCloud] if container checked", NSError(domain: "ICloudModlue", code: 101, userInfo: nil))
      return false
    }
    return true
  }

  private func _createDirIfNotExists(_ dirURL: URL, ifFail reject: RCTPromiseRejectBlock) {
    do {
      if(!FileManager.default.fileExists(atPath: dirURL.path)) {
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
      }
    } catch {
      reject("ERR_CREATE_DIR", error.localizedDescription, NSError(domain: "ICloudModlue", code: 102, userInfo: nil))
      return
    }
  }

  @objc
  func isICloudAvailable(_ resolve: RCTPromiseResolveBlock,
                         rejecter reject: RCTPromiseRejectBlock) {
    let token = FileManager.default.ubiquityIdentityToken
    resolve(token != nil)
  }

  @objc
  func writeFile(_ relativeFilePath: String, with content: String, and options: NSDictionary,resolver resolve: RCTPromiseResolveBlock,
                 rejecter reject: RCTPromiseRejectBlock) {
    guard _assertICloud(ifNil: reject) else { return }

    let override: Bool = (options["override"] as? Bool) ?? false

    let fileURL = icloudURL!.appendingPathComponent(relativeFilePath.rmPrefix("/"), isDirectory: false)

    _createDirIfNotExists(fileURL.deletingLastPathComponent(), ifFail: reject)

    if(FileManager.default.fileExists(atPath: fileURL.path) && !override) {
      reject("ERR_FILE_EXISTS", "file \(fileURL.path) already exists and override is false, so not create file", NSError(domain: "ICloudModlue", code: 201, userInfo: nil))
      return
    }

    do {
      try content.data(using: .utf8)?.write(to: fileURL)
      resolve(nil)
      return
    } catch {
      reject("ERR_WRITE_FILE", error.localizedDescription, NSError(domain: "ICloudModlue", code: 202, userInfo: nil))
      return
    }
  }

  @objc
  func copyFile(_ uriOrPath: String, to destRelativePath: String,  and options: NSDictionary, resolver resolve: RCTPromiseResolveBlock,
                rejecter reject: RCTPromiseRejectBlock) {
    guard _assertICloud(ifNil:reject) else { return }

    let override = options["override"] as? Bool ?? false

    var srcURL: URL
    if(uriOrPath.starts(with: "http")) {
       reject("ERR_NOT_SUPPORT", "not support http(s) currently", NSError(domain: "ICloudModlue", code: 301, userInfo: nil))
       return
    } else if(uriOrPath.starts(with: "file://")) {
      srcURL = URL(string: uriOrPath)!
    } else {
      srcURL = icloudURL!.appendingPathComponent(uriOrPath.rmPrefix("/"))
    }

    let destURL = icloudURL!.appendingPathComponent(destRelativePath.rmPrefix("/"))

    if(!FileManager.default.fileExists(atPath: srcURL.path)) {
      // here we print .absoluteString but not .path, because srcURL could be 'file://' or sth else format, '.path' will lose file protocol
      reject("ERR_FILE_NOT_EXISTS", "source file \(srcURL.absoluteString) not exists", NSError(domain: "ICloudModlue", code: 302, userInfo: nil))
      return
    }

    let destFileExists = FileManager.default.fileExists(atPath: destURL.path)
    do {
      if(destFileExists) {
        if(override) {
          let _ = try FileManager.default.replaceItemAt(destURL, withItemAt: srcURL, options: .withoutDeletingBackupItem)
          resolve(nil)
          return
        } else {
          reject("ERR_FILE_EXISTS", "file \(destURL.path) already exists and override is false, so not copy file", NSError(domain: "ICloudModlue", code: 303, userInfo: nil))
          return
        }
      } else {
        try FileManager.default.copyItem(at: srcURL, to: destURL)
        resolve(nil)
        return
      }
    }
    catch {
      reject("ERR_COPY_FILE", error.localizedDescription, NSError(domain: "ICloudModlue", code: 304, userInfo: nil))
      return
    }
  }

  @objc
  func fileExists(_ relativeFilePath: String, resolver resolve: RCTPromiseResolveBlock,
                  rejecter reject: RCTPromiseRejectBlock) {
    guard _assertICloud(ifNil:reject) else { return }

    let fileFullUrl = icloudURL!.appendingPathComponent(relativeFilePath.rmPrefix("/"))
    resolve(FileManager.default.fileExists(atPath: fileFullUrl.path))
  }

  @objc
  func readFile(_ relativeFilePath: String, resolver resolve: RCTPromiseResolveBlock,
                rejecter reject: RCTPromiseRejectBlock) {
    guard _assertICloud(ifNil:reject) else { return }

    let fileURL = icloudURL!.appendingPathComponent(relativeFilePath.rmPrefix("/"))
    if(!FileManager.default.fileExists(atPath: fileURL.path)) {
      reject("ERR_FILE_NOT_EXISTS", "file \(fileURL.path) not exists", NSError(domain: "ICloudModlue", code: 401, userInfo: nil))
      return
    }

    do {
      let content = try String(contentsOf: fileURL, encoding: .utf8)
      resolve(content)
    } catch {
      reject("ERR_READ_FILE", error.localizedDescription, NSError(domain: "ICloudModlue", code: 402, userInfo: nil))
    }
  }

  @objc
  func readDir(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
               rejecter reject: RCTPromiseRejectBlock) {
    guard _assertICloud(ifNil: reject) else { return }

    let dirURL = icloudURL!.appendingPathComponent(relativePath.rmPrefix("/"))

    if(!FileManager.default.fileExists(atPath: dirURL.path)) {
      reject("ERR_DIR_NOT_EXISTS", "dir \(dirURL.path) not exists", NSError(domain: "ICloudModlue", code: 501, userInfo: nil))
      return
    }

    do {
      let contents = try FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil)
      resolve(contents.map {
        $0.relativePath
      })
    } catch {
      reject("ERR_LIST_FILES", error.localizedDescription, NSError(domain: "ICloudModlue", code: 502, userInfo: nil))
      return
    }
  }

  @objc
  func unlink(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
              rejecter reject: RCTPromiseRejectBlock) {
    guard _assertICloud(ifNil: reject) else { return }

    let url = icloudURL!.appendingPathComponent(relativePath.rmPrefix("/"))
    if(!FileManager.default.fileExists(atPath: url.path)) {
      resolve(nil)
      return;
    }

    do {
      try FileManager.default.removeItem(at: url)
    } catch {
      reject("ERR_UNLINK", error.localizedDescription, NSError(domain: "ICloudModlue", code: 601, userInfo: nil))
      return
    }
    resolve(nil)
  }


  @objc
  func kvSync(resolver resolve: RCTPromiseResolveBlock,
                  rejecter reject: RCTPromiseRejectBlock) {

    let success = NSUbiquitousKeyValueStore.default.synchronize()
    if(success) {
      resolve(nil)
    } else {
      reject("ERR_KV_SYNC", "key-value sync failed, maybe:\n1. 'Key-value storage' capability not checked\n2. user's icloud not available", NSError(domain: "ICloudModlue", code: 701, userInfo: nil))
    }
  }

  @objc
  func kvSetItem(_ key: String, and value: String,resolver resolve: RCTPromiseResolveBlock,
                 rejecter reject: RCTPromiseRejectBlock) {
    NSUbiquitousKeyValueStore.default.set(value, forKey: key)
    resolve(nil)
  }

  @objc
  func kvGetItem(_ key: String, resolver resolve: RCTPromiseResolveBlock,
                 rejecter reject: RCTPromiseRejectBlock) {
    let res = NSUbiquitousKeyValueStore.default.string(forKey: key)
    resolve(res)
  }

  @objc
  func kvRemoveItem(_ key: String,resolver resolve: RCTPromiseResolveBlock,
                   rejecter reject: RCTPromiseRejectBlock) {
    NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
    resolve(nil)
  }

  @objc
  func kvGetAllItems(_ resolve: RCTPromiseResolveBlock,
                     rejecter reject: RCTPromiseRejectBlock) {
    resolve(NSUbiquitousKeyValueStore.default.dictionaryRepresentation)
  }
}
