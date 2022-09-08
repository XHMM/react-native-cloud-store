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

    override init() {
        super.init()

        // kv event
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default, queue: nil) { [self] u in
            onICloudKVStoreRemoteChanged(notification: u)
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
    private func icloudInvalid(then reject: RCTPromiseRejectBlock) -> Bool  {
        if iCloudURL == nil {
            reject("ERR_ICLOUD_DOWN", "iCloud container path not exists, maybe you did not enable iCloud documents capability.", NSError(domain: "", code: 0))
            return true
        }

        return false
    }

    private func createDirIfNotExists(_ dirURL: URL) throws {
        if(!FileManager.default.fileExists(atPath: dirURL.path)) {
            try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func getFullICloudURL(_ relativePath: String, isDirectory dir: Bool = false) -> URL  {
        
        if let iCloudPath = iCloudURL?.path,
            relativePath.starts(with: iCloudPath)
        {
            return URL(fileURLWithPath: relativePath, isDirectory: dir)
        }
        
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
            reject("ERR_KV_SYNC", "key-value sync failed, maybe caused by: You did not enable key-value storage capability.", NSError(domain: "", code: 0))
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
    func writeFile(_ relativeFilePath: String, withContent content: String, withOptions options: NSDictionary,resolver resolve: RCTPromiseResolveBlock,
                   rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let override: Bool = (options["override"] as? Bool) ?? false
        let fileURL = getFullICloudURL(relativeFilePath)

        do {
            try createDirIfNotExists(fileURL.deletingLastPathComponent())
        }catch {
            reject("ERR_COMMON", error.localizedDescription, NSError(domain: "", code: 0))
            return;
        }

        if(FileManager.default.fileExists(atPath: fileURL.path) && !override) {
            reject("ERR_FILE_EXIST", "file \(fileURL.path) already exists and override is false, so not create file", NSError(domain: "", code: 0))
            return
        }

        do {
            try content.data(using: .utf8)?.write(to: fileURL)
            resolve(nil)
            return
        } catch {
            reject("ERR_WRITE_FILE", error.localizedDescription, NSError(domain: "", code: 0))
            return
        }
    }

    @objc
    func readFile(_ relativeFilePath: String, resolver resolve: RCTPromiseResolveBlock,
                  rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let fileURL = getFullICloudURL(relativeFilePath)
        if(!FileManager.default.fileExists(atPath: fileURL.path)) {
            reject("ERR_FILE_NOT_EXIST", "file \(fileURL.path) not exists", NSError(domain: "", code: 0))
            return
        }

        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            resolve(content)
        } catch {
            reject("ERR_READ_FILE", error.localizedDescription, NSError(domain: "", code: 0))
            return
        }
    }
}

// MARK: dir
extension CloudStoreModule {
    @objc
    func readDir(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
                 rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let dirURL = getFullICloudURL(relativePath)

        if(!FileManager.default.fileExists(atPath: dirURL.path)) {
            reject("ERR_DIR_NOT_EXIST", "dir \(dirURL.path) not exist", NSError(domain: "", code: 0))
            return
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil)
            resolve(contents.map {
                $0.relativePath
            })
        } catch {
            reject("ERR_LIST_FILES", error.localizedDescription, NSError(domain: "", code: 0))
            return
        }
    }

    @objc
    func createDir(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
                   rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let url = getFullICloudURL(relativePath, isDirectory: true)
        do {
            try createDirIfNotExists(url)
            resolve(nil)
        }catch {
            reject("ERR_COMMON", error.localizedDescription, NSError(domain: "", code: 0))
            return;
        }
    }

    @objc
    func moveDir(_ relativeFromPath: String, to relativeToPath: String, resolver resolve: RCTPromiseResolveBlock,
                 rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        do {
            let srcDirURL = getFullICloudURL(relativeFromPath)
            let destDirURL = getFullICloudURL(relativeToPath)
            try FileManager.default.moveItem(at: srcDirURL, to: destDirURL)
            resolve(nil)
        } catch {
            reject("ERR_MOVE_DIR", error.localizedDescription, NSError(domain: "", code:0))
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
    let progress: Float?
    let isDir: Bool?
    var dictionary: [String: Any] {
        return [
            "type": type.rawValue, // cannot use swift enum here, will be null in js side
            "path": path,
            "progress": progress as Any,
            "isDir": isDir as Any
        ]
    }
    var nsDictionary: NSDictionary {
        return dictionary as NSDictionary
    }
}

// MARK: file or dir
extension CloudStoreModule {

    struct ERRNotExist: LocalizedError {
        let path: String
        var errorDescription: String? {
            "folder of \"\(path)\" not exists, you need create it first"
        }
    }
    // error message from `FileManager.default.copyItem` is misleading, when dest folder not exists, error message showed src path not exists, so manually modify error message
    private func copyItem(at: URL, to: URL) throws {
        let parentURL = to.deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: parentURL.path) {
            try FileManager.default.copyItem(at: at, to: to)
        } else {
            throw ERRNotExist(path:  parentURL.path)
        }
    }

    @objc
    func copy(_ srcRelativePath: String, to destRelativePath: String,  with options: NSDictionary, resolver resolve: RCTPromiseResolveBlock,
              rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let override = options["override"] as? Bool ?? false

        let srcURL = getFullICloudURL(srcRelativePath)
        let destURL = getFullICloudURL(destRelativePath)

        let destExists = FileManager.default.fileExists(atPath: destURL.path)
        do {
            if(destExists) {
                if(override) {
                    let _ = try FileManager.default.replaceItemAt(destURL, withItemAt: srcURL, options: .withoutDeletingBackupItem)
                    resolve(nil)
                    return
                } else {
                    reject("ERR_DEST_EXIST", "file or dir \"\(destURL.path)\" already exists", NSError(domain: "", code: 0))
                    return
                }
            } else {
                try copyItem(at: srcURL, to: destURL)
                resolve(nil)
                return
            }
        }
        catch {
            reject("ERR_COPY", error.localizedDescription, NSError(domain: "", code: 0))
            return
        }
    }

    @objc
    func unlink(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
                rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let url = getFullICloudURL(relativePath, isDirectory: relativePath.hasSuffix("/"))
        if(!FileManager.default.fileExists(atPath: url.path)) {
            resolve(nil)
            return;
        }

        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            reject("ERR_UNLINK", error.localizedDescription, NSError(domain: "", code: 0))
            return
        }
        resolve(nil)
    }

    @objc
    func exist(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
               rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let fileFullUrl = getFullICloudURL(relativePath)
        resolve(FileManager.default.fileExists(atPath: fileFullUrl.path))
    }

    @objc
    func stat(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
              rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let url = getFullICloudURL(relativePath)
        if(!FileManager.default.fileExists(atPath: url.path)) {
            reject("ERR_NOT_EXIST", "file/folder of \(url.path) not exists", NSError(domain: "", code: 0))
            return
        }

        do {
            let resources = try url.resourceValues(forKeys: [
                .isUbiquitousItemKey,
                .ubiquitousItemContainerDisplayNameKey,

                    .ubiquitousItemDownloadRequestedKey,
                .ubiquitousItemIsDownloadingKey,
                .ubiquitousItemDownloadingStatusKey,
                .ubiquitousItemDownloadingErrorKey,

                    .ubiquitousItemIsUploadedKey,
                .ubiquitousItemIsUploadingKey,
                .ubiquitousItemUploadingErrorKey,

                    .ubiquitousItemHasUnresolvedConflictsKey,

                    .contentModificationDateKey,
                .creationDateKey,
                .nameKey,
                .localizedNameKey
            ])
            let dict = NSMutableDictionary()

            dict["isInICloud"] = resources.isUbiquitousItem
            dict["containerDisplayName"] = resources.ubiquitousItemContainerDisplayName

            dict["isDownloading"] = resources.ubiquitousItemIsDownloading
            dict["hasCalledDownload"] = resources.ubiquitousItemDownloadRequested
            dict["downloadStatus"] = resources.ubiquitousItemDownloadingStatus
            dict["downloadError"] = resources.ubiquitousItemDownloadingError?.localizedDescription

            dict["isUploaded"] = resources.ubiquitousItemIsUploaded
            dict["isUploading"] = resources.ubiquitousItemIsUploading
            dict["uploadError"] = resources.ubiquitousItemUploadingError?.localizedDescription

            dict["hasUnresolvedConflicts"] = resources.ubiquitousItemHasUnresolvedConflicts

            if let modifyDate = resources.contentModificationDate {
                dict["modifyTimestamp"] = modifyDate.timeIntervalSince1970 * 1000
            } else {
                dict["modifyTimestamp"] = nil
            }
            if let createDate = resources.contentModificationDate {
                dict["createTimestamp"] = createDate.timeIntervalSince1970 * 1000
            } else {
                dict["createTimestamp"] = nil
            }
            dict["name"] = resources.name
            dict["localizedName"] = resources.localizedName

            resolve(dict)
        } catch {
            reject("ERR_STAT", error.localizedDescription, NSError(domain: "", code: 0))
        }
    }
}

// MARK: upload, persis(download)
extension CloudStoreModule {

    ///  init and start query
    /// - Parameters:
    ///   - url:
    ///   - resolve:
    ///   - queryCallback: this callback wa used to filter data you want
    private func initAndStartQuery(iCloudURL url: URL, resolver resolve: @escaping RCTPromiseResolveBlock, using queryCallback: @escaping (_ query: NSMetadataQuery) -> (NSMutableArray,Bool)) {
        func getChangedItems(_ notif: Notification) -> NSDictionary {
            // https://developer.apple.com/documentation/coreservices/file_metadata/mdquery/query_result_change_keys
            let dict = NSMutableDictionary()
            dict["added"] = (notif.userInfo?["kMDQueryUpdateAddedItems"] as?  [NSMetadataItem] ?? []).map{ (i) in
                return i.value(forAttribute: NSMetadataItemPathKey)
            }
            dict["changed"] = (notif.userInfo?["kMDQueryUpdateChangedItems"] as?  [NSMetadataItem] ?? []).map{ (i) in
                return i.value(forAttribute: NSMetadataItemPathKey)
            }
            dict["removed"] = (notif.userInfo?["kMDQueryUpdateRemovedItems"] as?  [NSMetadataItem] ?? []).map{ (i) in
                return i.value(forAttribute: NSMetadataItemPathKey)
            }
            return dict
        }

        let query = NSMetadataQuery()
        query.operationQueue = .main
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryUbiquitousDataScope]
        query.predicate = NSPredicate(format: "%K CONTAINS %@", NSMetadataItemPathKey,url.path)
        query.notificationBatchingInterval = 0.2

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidStartGathering, object: query, queue: query.operationQueue, using: { [self] notification in
            Logger.log("[start results]:\n")

            let (res, _) = queryCallback(query)
            if hasListeners {
                sendEvent(withName: "onICloudDocumentsStartGathering", body: NSDictionary(dictionary: [
                    "info": getChangedItems(notification),
                    "detail": res
                ]))
            }
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryGatheringProgress, object: query,  queue: query.operationQueue, using: { [self] notification in
            Logger.log("[gather results]:\n")
            let (res, _) = queryCallback(query)

            if hasListeners {
                sendEvent(withName: "onICloudDocumentsGathering", body: NSDictionary(dictionary: [
                    "info": getChangedItems(notification),
                    "detail": res
                ]))
            }
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query,  queue: query.operationQueue, using: { [self] notification in
            Logger.log("[finish results]:\n")
            let (res, _) = queryCallback(query)
            if hasListeners {
                sendEvent(withName: "onICloudDocumentsFinishGathering", body: NSDictionary(dictionary: [
                    "info": getChangedItems(notification),
                    "detail": res
                ]))
            }
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidUpdate, object: query,  queue: query.operationQueue, using: {
            [self] notification in
            Logger.log("[update results]:\n")
            let (res, ended) = queryCallback(query)
            if ended {
                Logger.log("persist query stopped")
                query.stop()
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidUpdate, object: query)
            }
            if hasListeners {
                sendEvent(withName: "onICloudDocumentsUpdateGathering", body: NSDictionary(dictionary: [
                    "info": getChangedItems(notification),
                    "detail": res
                ]))
            }
        })

        let _ = query.start()
        resolve(nil)
    }

    @objc
    func upload(_ fullLocalPath: String, to relativePath: String, resolver resolve: @escaping RCTPromiseResolveBlock,
                rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let localURL = URL(string: fullLocalPath)
        guard let localURL = localURL else {
            reject("ERR_INVALID_PATH", "local path \"\(fullLocalPath)\" is invalid", NSError(domain: "", code: 0))
            return
        }
        let iCloudURL = getFullICloudURL(relativePath)

        do {
            try copyItem(at: localURL, to: iCloudURL)
        } catch {
            reject("ERR_COPY_TO_ICLOUD", error.localizedDescription, NSError(domain: "", code: 0))
            return
        }

        initAndStartQuery(iCloudURL: iCloudURL, resolver: resolve) { (query) in
            query.disableUpdates()

            var arr: [ICloudGatheringFile] = []
            var ended = false
            for item in query.results {
                let item = item as! NSMetadataItem
                let fileItemURL = item.value(forAttribute: NSMetadataItemURLKey) as! URL
                let values = try? fileItemURL.resourceValues(forKeys: [.isDirectoryKey, .ubiquitousItemIsUploadingKey])
                let isDir = values?.isDirectory
                let isUploading = values?.ubiquitousItemIsUploading
                let uploadProgress = item.value(forAttribute: NSMetadataUbiquitousItemPercentUploadedKey) as? Float
                arr.append(ICloudGatheringFile(type: .upload, path: fileItemURL.path, progress: uploadProgress, isDir: isDir))
                if isUploading == false && uploadProgress == 100 {
                    ended = true
                }
                print(fileItemURL," upload info: uploadProgress-\(String(describing: uploadProgress))")
            }

            let m: NSMutableArray = NSMutableArray()
            m.addObjects(from: arr.map{$0.nsDictionary})
            if !ended {
                query.enableUpdates()
            }
            return (m, ended)
        }
    }

    @objc
    func persist(_ relativePath: String, resolver resolve: @escaping RCTPromiseResolveBlock,
                 rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let iCloudURL = getFullICloudURL(relativePath)

        do {
            // TODO: if url is a directory, this only download dir but not files under it, need to manually handle it, check https://github.com/farnots/iCloudDownloader/blob/master/iCloudDownlader/Downloader.swift for inspiration
            try FileManager.default.startDownloadingUbiquitousItem(at: iCloudURL)
        } catch {
            reject("ERR_DOWNLOAD_ICLOUD_FILE", error.localizedDescription, NSError(
                domain: "", code: 0))
            return
        }

        initAndStartQuery(iCloudURL: iCloudURL, resolver: resolve) { query in
            query.disableUpdates()
            var arr: [ICloudGatheringFile] = []
            var ended = false
            for item in query.results {
                let item = item as! NSMetadataItem
                let fileItemURL = item.value(forAttribute: NSMetadataItemURLKey) as! URL

                let values = try? fileItemURL.resourceValues(forKeys: [.isDirectoryKey, .ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey])
                let isDir = values?.isDirectory
                let downloadingStatus = values?.ubiquitousItemDownloadingStatus
                let downloading = values?.ubiquitousItemIsDownloading
                let downloadingProgress = item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey) as? Float

                arr.append(ICloudGatheringFile(type: .persist, path: fileItemURL.path, progress: downloadingProgress, isDir: isDir))

                // stop query when one file progress is 100
                if downloading == false && downloadingProgress == 100 {
                    ended = true
                }
                Logger.log("[download-info]:\n","url  \(fileItemURL)\nisDownloading  \(String(describing: downloading))\nstatus  \(String(describing: downloadingStatus))\nprogress  \(String(describing: downloadingProgress))\n")
            }

            if !ended {
                query.enableUpdates()
            }

            let m: NSMutableArray = NSMutableArray()
            m.addObjects(from: arr.map{$0.nsDictionary})
            return (m,ended)
        }
    }
}

class Logger {
    public static func log(_ items: Any...) {
    #if DEBUG
        print(items)
    #endif
    }
}
