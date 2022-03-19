import Foundation

extension String {
    func rmPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

@objc(CloudStoreModule)
class CloudStoreModule : RCTEventEmitter {
    private var hasListeners = false
    private var iCloudURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)
    }
    private let domain = "iCloudModule"
    private let uploadQuery: NSMetadataQuery = NSMetadataQuery()
    private let downloadQuery: NSMetadataQuery = NSMetadataQuery()

    override init() {
        super.init()

        // kv event
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default, queue: nil) { [self] u in
            onICloudKVStoreRemoteChanged(notification: u)
        }

        // iCloud event
        uploadQuery.operationQueue = .main
        uploadQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryUbiquitousDataScope]

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidStartGathering, object: uploadQuery, queue: uploadQuery.operationQueue) { [self] u in
            self.onICloudDocumentsStartGathering(notification: u)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryGatheringProgress, object: uploadQuery, queue: uploadQuery.operationQueue) { [self] u in

            self.onICloudDocumentsGathering(notification: u)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: uploadQuery, queue: uploadQuery.operationQueue) { [self] u in

            self.onICloudDocumentsFinishGathering(notification: u)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidUpdate, object: uploadQuery, queue: uploadQuery.operationQueue) { [self] u in
            self.onICloudDocumentsUpdateGathering(notification: u)
        }

        downloadQuery.operationQueue = .main
        downloadQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryUbiquitousDataScope]

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidStartGathering, object: downloadQuery, queue: downloadQuery.operationQueue) { [self] u in
            self.onICloudDocumentsStartGathering(notification: u)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryGatheringProgress, object: downloadQuery, queue: downloadQuery.operationQueue) { [self] u in

            self.onICloudDocumentsGathering(notification: u)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: downloadQuery, queue: downloadQuery.operationQueue) { [self] u in

            self.onICloudDocumentsFinishGathering(notification: u)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidUpdate, object: downloadQuery, queue: downloadQuery.operationQueue) { [self] u in
            self.onICloudDocumentsUpdateGathering(notification: u)
        }
    }

    override func supportedEvents() -> [String]! {
        return ["onICloudKVStoreRemoteChanged", "onICloudDocumentsStartGathering", "onICloudDocumentsGathering", "onICloudDocumentsFinishGathering", "onICloudDocumentsUpdateGathering"]
    }

    override func constantsToExport() -> [AnyHashable : Any] {
        return ["iCloudContainerPath": iCloudURL?.path ?? ""]
    }

    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return false
    }

    @objc
    override func startObserving() {
        hasListeners = true
    }

    @objc
    override func stopObserving() {
        hasListeners = false
    }

    // make sure iCloud exists before doing extra things
    private func assertICloud(ifNil reject: RCTPromiseRejectBlock) -> Bool {
        guard iCloudURL != nil else {
            reject("ERR_PATH_NOT_EXIST", "iCloud container path not exists, maybe you did not enable iCloud documents capability, please check https://react-native-cloud-store.vercel.app/docs/get-started for details", NSError(domain: domain, code: 101, userInfo: nil))
            return false
        }
        return true
    }

    private func createDirIfNotExists(_ dirURL: URL, ifFail reject: RCTPromiseRejectBlock) {
        do {
            if(!FileManager.default.fileExists(atPath: dirURL.path)) {
                try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            reject("ERR_CREATE_DIR", error.localizedDescription, NSError(domain: "iCloudModule", code: 102, userInfo: nil))
            return
        }
    }

    private func fullICloudURL(_ relativePath: String, isDirectory dir: Bool = false) -> URL  {
        return iCloudURL!.appendingPathComponent(relativePath.rmPrefix("/"), isDirectory: dir)
    }
}

// MARK: kv
extension CloudStoreModule {
    @objc
    func onICloudKVStoreRemoteChanged(notification:Notification) {
        if hasListeners {
            sendEvent(withName: "onICloudKVStoreRemoteChanged", body: notification.userInfo)
        }
    }

    @objc
    func kvSync(_ resolve: RCTPromiseResolveBlock,
                rejecter reject: RCTPromiseRejectBlock) {

        let success = NSUbiquitousKeyValueStore.default.synchronize()
        if(success) {
            resolve(nil)
        } else {
            reject("ERR_KV_SYNC", "key-value sync failed, maybe caused by: 1.You did not enable key-value storage capability, please check https://react-native-cloud-store.vercel.app/docs/get-started for details. 2.User's iCloud not available.", NSError(domain: domain, code: 701, userInfo: nil))
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

// MARK: helpers
extension CloudStoreModule {
    @objc
    func isICloudAvailable(_ resolve: RCTPromiseResolveBlock,
                           rejecter reject: RCTPromiseRejectBlock) {
        let token = FileManager.default.ubiquityIdentityToken
        resolve(token != nil)
    }
}

// MARK: file
extension CloudStoreModule {
    @objc
    func writeFile(_ relativeFilePath: String, with content: String, and options: NSDictionary,resolver resolve: RCTPromiseResolveBlock,
                   rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil: reject) else { return }

        let override: Bool = (options["override"] as? Bool) ?? false

        let fileURL = fullICloudURL(relativeFilePath)

        createDirIfNotExists(fileURL.deletingLastPathComponent(), ifFail: reject)

        if(FileManager.default.fileExists(atPath: fileURL.path) && !override) {
            reject("ERR_FILE_EXISTS", "file \(fileURL.path) already exists and override is false, so not create file", NSError(domain: domain, code: 201, userInfo: nil))
            return
        }

        do {
            try content.data(using: .utf8)?.write(to: fileURL)
            resolve(nil)
            return
        } catch {
            reject("ERR_WRITE_FILE", error.localizedDescription, NSError(domain: domain, code: 202, userInfo: nil))
            return
        }
    }

    @objc
    func readFile(_ relativeFilePath: String, resolver resolve: RCTPromiseResolveBlock,
                  rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil:reject) else { return }

        let fileURL = fullICloudURL(relativeFilePath)
        if(!FileManager.default.fileExists(atPath: fileURL.path)) {
            reject("ERR_FILE_NOT_EXISTS", "file \(fileURL.path) not exists", NSError(domain: domain, code: 401, userInfo: nil))
            return
        }

        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let resources = try fileURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
            let dict = NSMutableDictionary()
            dict["content"] = content;
            dict["downloadStatus"] = resources.ubiquitousItemDownloadingStatus!
            // not support swift struct, will be null in js
            resolve(dict)
        } catch {
            reject("ERR_READ_FILE", error.localizedDescription, NSError(domain: domain, code: 402, userInfo: nil))
        }
    }
}

// MARK: dir
extension CloudStoreModule {
    @objc
    func readDir(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
                 rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil: reject) else { return }

        let dirURL = fullICloudURL(relativePath)

        if(!FileManager.default.fileExists(atPath: dirURL.path)) {
            reject("ERR_DIR_NOT_EXISTS", "dir \(dirURL.path) not exists", NSError(domain: domain, code: 501, userInfo: nil))
            return
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil)
            resolve(contents.map {
                $0.relativePath
            })
        } catch {
            reject("ERR_LIST_FILES", error.localizedDescription, NSError(domain: domain, code: 502, userInfo: nil))
            return
        }
    }

    @objc
    func createDir(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
                   rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil: reject) else { return }
        let url = fullICloudURL(relativePath, isDirectory: true)
        createDirIfNotExists(url, ifFail: reject)
        resolve(nil)
    }

    @objc
    func moveDir(_ relativeFromPath: String, to relativeToPath: String, resolver resolve: RCTPromiseResolveBlock,
                 rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil: reject) else { return }
        do {
            let srcDirURL = fullICloudURL(relativeFromPath)
            let destDirURL = fullICloudURL(relativeToPath)
            try FileManager.default.moveItem(at: srcDirURL, to: destDirURL)
            resolve(nil)
        } catch {
            reject("ERR_MOVE_DIR", error.localizedDescription, NSError(domain: domain, code: 801, userInfo: nil))
            return
        }
    }
}

enum ICloudGatheringFileType:String{
    case upload = "upload"
    case persist = "persist"
}
struct ICloudGatheringFile {
    let type: ICloudGatheringFileType
    let path: String
    let progress: Float
    var dictionary: [String: Any] {
        return ["type": type.rawValue, // cannot use swift enum here, will be null in js side
                "path": path,
                "progress": progress]
    }
    var nsDictionary: NSDictionary {
        return dictionary as NSDictionary
    }
}
// MARK: file or dir
extension CloudStoreModule {
    private func logUploadInfo() -> NSMutableArray {
        var arr: [ICloudGatheringFile] = []
        for item in uploadQuery.results {
            let item = item as! NSMetadataItem
            let fileItemURL = item.value(forAttribute: NSMetadataItemURLKey) as! URL

            let uploadProgress = item.value(forAttribute: NSMetadataUbiquitousItemPercentUploadedKey) as! NSNumber
            arr.append(ICloudGatheringFile(type: .upload, path: fileItemURL.path, progress: Float(truncating: uploadProgress)))
            print(fileItemURL,"\n  upload info:\n uploadProgress-\(uploadProgress)")
        }

        let m: NSMutableArray = NSMutableArray()
        m.addObjects(from: arr.map{$0.nsDictionary})
        return m
    }
    private func logDownloadInfo() -> NSMutableArray {
        var arr: [ICloudGatheringFile] = []
        for item in downloadQuery.results {
            let item = item as! NSMetadataItem
            let fileItemURL = item.value(forAttribute: NSMetadataItemURLKey) as! URL

            let downloading = item.value(forAttribute: NSMetadataUbiquitousItemIsDownloadingKey) as! Bool
            // let ?? = item.value(forAttribute: NSMetadataUbiquitousItemDownloadRequestedKey)
            let downloadingStatus = item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as! String
            let downloadingProgress = item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey) as! NSNumber
            arr.append(ICloudGatheringFile(type: .persist, path: fileItemURL.path, progress: Float(truncating: downloadingProgress)))
            print(fileItemURL,"\n  download info:\n isDownloading-\(downloading),status-\(downloadingStatus),progress-\(downloadingProgress)")
        }

        let m: NSMutableArray = NSMutableArray()
        m.addObjects(from: arr.map{$0.nsDictionary})
        return m
    }

    // https://stackoverflow.com/questions/39176196/how-to-provide-a-localized-description-with-an-error-type-in-swift
    private enum MyError: LocalizedError {
        case notExists(path: String)

        public var errorDescription: String? {
            switch self {
            case .notExists(let path):
                return "dest folder \"\(path)\" not exists, you need create it first"
            }
        }
    }

    // The error message of `copyItem` is misleading: when dest path folder not exists, error message is src file not exists which is not the right error message, so here I handled this bad behavior
    private func copyItem(at: URL, to: URL) throws {
        let parentURL = to.deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: parentURL.path) {
            try FileManager.default.copyItem(at: at, to: to)
        } else {
            throw MyError.notExists(path: parentURL.path)
        }
    }

    @objc
    func onICloudDocumentsStartGathering(notification:Notification) {
        if hasListeners {
            print("\n start results:")
            let obj = notification.object as! NSObject
            let res = obj == uploadQuery ? logUploadInfo() : obj == downloadQuery ? logDownloadInfo() : []
            sendEvent(withName: "onICloudDocumentsStartGathering", body: res)
        }
    }

    @objc
    func onICloudDocumentsGathering(notification:Notification) {
        if hasListeners{
            print("\n gathering results:")
            let obj = notification.object as! NSObject
            let res = obj == uploadQuery ? logUploadInfo() : obj == downloadQuery ? logDownloadInfo() : []
            sendEvent(withName: "onICloudDocumentsGathering", body: res)
        }
    }

    @objc
    func onICloudDocumentsFinishGathering(notification:Notification) {
        if hasListeners {
            print("\n finish results:")
            let obj = notification.object as! NSObject
            let res = obj == uploadQuery ? logUploadInfo() : obj == downloadQuery ? logDownloadInfo() : []
            sendEvent(withName: "onICloudDocumentsFinishGathering", body: res)
        }
    }

    @objc
    func onICloudDocumentsUpdateGathering(notification:Notification) {
        if hasListeners {
            print("\n update results:")
            let obj = notification.object as! NSObject
            let res = obj == uploadQuery ? logUploadInfo() : obj == downloadQuery ? logDownloadInfo() : []
            sendEvent(withName: "onICloudDocumentsUpdateGathering", body: res)
        }
    }

    @objc
    func copy(_ srcRelativePath: String, to destRelativePath: String,  and options: NSDictionary, resolver resolve: RCTPromiseResolveBlock,
              rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil:reject) else { return }

        let override = options["override"] as? Bool ?? false

        let srcURL = fullICloudURL(srcRelativePath)
        let destURL = fullICloudURL(destRelativePath)

        let destExists = FileManager.default.fileExists(atPath: destURL.path)
        do {
            if(destExists) {
                if(override) {
                    let _ = try FileManager.default.replaceItemAt(destURL, withItemAt: srcURL, options: .withoutDeletingBackupItem)
                    resolve(nil)
                    return
                } else {
                    reject("ERR_DEST_EXISTS", "file or dir \"\(destURL.path)\" already exists", NSError(domain: domain, code: 303, userInfo: nil))
                    return
                }
            } else {
                try copyItem(at: srcURL, to: destURL)
                resolve(nil)
                return
            }
        }
        catch {
            reject("ERR_COPY", error.localizedDescription, NSError(domain: domain, code: 304, userInfo: nil))
            return
        }
    }

    @objc
    func unlink(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
                rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil: reject) else { return }

        let url = fullICloudURL(relativePath, isDirectory: relativePath.hasSuffix("/"))
        if(!FileManager.default.fileExists(atPath: url.path)) {
            resolve(nil)
            return;
        }

        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            reject("ERR_UNLINK", error.localizedDescription, NSError(domain: domain, code: 601, userInfo: nil))
            return
        }
        resolve(nil)
    }

    @objc
    func exist(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
               rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil:reject) else { return }

        let fileFullUrl = fullICloudURL(relativePath)
        resolve(FileManager.default.fileExists(atPath: fileFullUrl.path))
    }

    @objc
    func upload(_ fullLocalPath: String, to relativePath: String, resolver resolve: RCTPromiseResolveBlock,
                rejecter reject: RCTPromiseRejectBlock) {
        let localURL = URL(string: fullLocalPath)
        guard let localURL = localURL else {
            reject("ERR_INVALID_PATH", "local path \"\(fullLocalPath)\" is invalid", NSError(domain: domain, code: 801, userInfo: nil))
            return
        }
        do {
            let icloudURL = fullICloudURL(relativePath)
            try copyItem(at: localURL, to: icloudURL)
            DispatchQueue.main.async { [self] in
                uploadQuery.predicate = NSPredicate(format: "%K CONTAINS %@", NSMetadataItemPathKey,icloudURL.path)
                let _ = uploadQuery.start()
                uploadQuery.enableUpdates()
            }

        } catch {
            reject("ERR_COPY_TO_ICLOUD", error.localizedDescription, NSError(domain: domain, code: 304, userInfo: nil))
        }
    }

    @objc
    func persist(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
                 rejecter reject: RCTPromiseRejectBlock) {
        let icloudURL = fullICloudURL(relativePath)
        do {
            try FileManager.default.startDownloadingUbiquitousItem(at: icloudURL)
            downloadQuery.predicate = NSPredicate(format: "%K CONTAINS %@", NSMetadataItemPathKey,icloudURL.path)
            let _ = downloadQuery.start()
            downloadQuery.enableUpdates()
            resolve(nil)
        } catch {
            reject("ERR_DOWNLOAD_ICLOUD_FILE", error.localizedDescription, NSError(
                domain: domain, code: 801, userInfo: nil))
        }
    }
}

