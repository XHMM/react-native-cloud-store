import Foundation

extension String {
    func rmPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

extension FileManager {
    func createDirIfNotExists(_ dirURL: URL) throws {
        if(!FileManager.default.fileExists(atPath: dirURL.path)) {
            try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
}

@objc(CloudStoreModule)
class CloudStoreModule : RCTEventEmitter {
    private var hasListeners = false
    private var icloudCurrentToken = FileManager.default.ubiquityIdentityToken

    override init() {
        super.init()

        // kv event
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default, queue: nil) { [self] u in
            onICloudKVStoreRemoteChanged(notification: u)
        }

        // icloud event
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSUbiquityIdentityDidChange, object: nil, queue: nil) { [self] u in
            onICloudIdentityDidChange(notification: u)
        }
    }

    override func supportedEvents() -> [String]! {
        return [
            "onICloudKVStoreRemoteChanged",
            "onICloudIdentityDidChange",
            "onICloudDocumentsStartGathering",
            "onICloudDocumentsGathering",
            "onICloudDocumentsFinishGathering",
            "onICloudDocumentsUpdateGathering"
        ]
    }

    override func constantsToExport() -> [AnyHashable : Any] {
        return ["defaultICloudContainerPath": FileManager.default.url(forUbiquityContainerIdentifier: nil)?.path ?? ""]
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

// MARK: icloud helpers
extension CloudStoreModule {
    // make sure iCloud available before doing extra things
    private func icloudInvalid(then reject: RCTPromiseRejectBlock) -> Bool  {
        if FileManager.default.ubiquityIdentityToken == nil {
            reject("ERR_ICLOUD_DOWN", "iCloud not available, maybe caused by:\n\t1. You did not enable iCloud documents capability.\n\t2.User not logged in with apple id.\n\t3.User disabled iCloud.", NSError(domain: "", code: 0))
            return true
        }

        return false
    }

    @objc
    func getICloudURL(_ containerIdentifier: String?, resolver resolve: @escaping RCTPromiseResolveBlock,
                      rejecter reject: @escaping RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        DispatchQueue.global(qos: .userInitiated).async {
            // As doc https://developer.apple.com/documentation/foundation/filemanager/1411653-url said: Do not call this method from your app’s main thread. Because this method might take a nontrivial amount of time to set up iCloud and return the requested URL
            let url = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)
            if let url = url {
                resolve(url.path)
            } else {
                reject("ERR_ICLOUD_PATH", "cannot get iCloud path, make sure you passed a right container id and correctly configured entitlements", NSError(domain: "", code: 0))
            }

        }
    }

    @objc
    func onICloudIdentityDidChange(notification:Notification) {
        let newToken = FileManager.default.ubiquityIdentityToken
        var tokenChanged = false
        if let newToken = newToken {
            tokenChanged = !newToken.isEqual(icloudCurrentToken)
        } else {
            tokenChanged = icloudCurrentToken != nil
        }
        icloudCurrentToken = newToken;

        if hasListeners {
            sendEvent(withName: "onICloudIdentityDidChange", body: [
                "tokenChanged":  tokenChanged
            ])
        }
    }

    @objc
    func isICloudAvailable(_ resolve: RCTPromiseResolveBlock,
                           rejecter reject: RCTPromiseRejectBlock) {
        let token = FileManager.default.ubiquityIdentityToken
        resolve(token != nil)
    }

    @objc
    func getDefaultICloudContainerPath(_ resolve: RCTPromiseResolveBlock,
                           rejecter reject: RCTPromiseRejectBlock) {
        let path = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.path ?? nil;
        resolve(path)
    }
}

// MARK: icloud file functions
extension CloudStoreModule {
    @objc
    func writeFile(_ path: String, withContent content: String, with options: NSDictionary,resolver resolve: @escaping RCTPromiseResolveBlock,
                   rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let override: Bool = (options["override"] as? Bool) ?? false
        let fileURL = URL(fileURLWithPath: path)
        let id = (options["id"] as? String)

        do {
            try FileManager.default.createDirIfNotExists(fileURL.deletingLastPathComponent())
        }catch {
            reject("ERR_COMMON", error.localizedDescription, NSError(domain: "", code: 0))
            return;
        }

        if(FileManager.default.fileExists(atPath: fileURL.path) && !override) {
            reject("ERR_FILE_EXIST", "file \(fileURL.path) already exists and override is false, so not create file", NSError(domain: "", code: 0))
            return
        }

        do {
            try content.data(using: .utf8)?.write(to: fileURL, options: .atomic)
            if let id = id {
                listenUpload(iCloudURL: fileURL, id: id, resolver: resolve)
            } else {
                resolve(nil)
            }
            return
        } catch {
            reject("ERR_WRITE_FILE", error.localizedDescription, NSError(domain: "", code: 0))
            return
        }
    }

    @objc
    func readFile(_ path: String, resolver resolve: RCTPromiseResolveBlock,
                  rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let fileURL = URL(fileURLWithPath: path)
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

// MARK: icloud dir functions
extension CloudStoreModule {
    @objc
    func readDir(_ path: String, resolver resolve: RCTPromiseResolveBlock,
                 rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let dirURL = URL(fileURLWithPath: path)

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
    func createDir(_ path: String, resolver resolve: RCTPromiseResolveBlock,
                   rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let url = URL(fileURLWithPath: path, isDirectory: true)
        do {
            try FileManager.default.createDirIfNotExists(url)
            resolve(nil)
        }catch {
            reject("ERR_COMMON", error.localizedDescription, NSError(domain: "", code: 0))
            return;
        }
    }

    @objc
    func moveDir(_ fromPath: String, to toPath: String, resolver resolve: RCTPromiseResolveBlock,
                 rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        do {
            let fromDirURL = URL(fileURLWithPath: fromPath)
            let toDirURL = URL(fileURLWithPath: toPath)
            try FileManager.default.moveItem(at: fromDirURL, to: toDirURL)
            resolve(nil)
        } catch {
            reject("ERR_MOVE_DIR", error.localizedDescription, NSError(domain: "", code:0))
            return
        }
    }
}

enum ICloudGatheringFileType:String{
    case upload = "upload"
    case download = "download"
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

// MARK: icloud file/dir functions
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
    func copy(_ fromPath: String, to toPath: String,  with options: NSDictionary, resolver resolve: RCTPromiseResolveBlock,
              rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let override = options["override"] as? Bool ?? false

        let fromURL = URL(fileURLWithPath: fromPath)
        let toURL = URL(fileURLWithPath: toPath)

        let destExists = FileManager.default.fileExists(atPath: toURL.path)
        do {
            if(destExists) {
                if(override) {
                    let _ = try FileManager.default.replaceItemAt(toURL, withItemAt: fromURL, options: .withoutDeletingBackupItem)
                    resolve(nil)
                    return
                } else {
                    reject("ERR_DEST_EXIST", "file or dir of \"\(toURL.path)\" already exists", NSError(domain: "", code: 0))
                    return
                }
            } else {
                try copyItem(at: fromURL, to: toURL)
                resolve(nil)
                return
            }
        }
        catch {
            reject("ERR_COPY", error.localizedDescription, NSError(domain: "", code: 0))
            return
        }
    }

    // TODO: I'm not too clearly know about the difference between using setUbiquitous(..) to move/delete icloud file and below way:
    @objc
    func unlink(_ path: String, resolver resolve: RCTPromiseResolveBlock,
                rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let url = URL(fileURLWithPath: path)
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
    func exist(_ path: String, resolver resolve: RCTPromiseResolveBlock,
               rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let fileFullUrl = URL(fileURLWithPath: path)
        resolve(FileManager.default.fileExists(atPath: fileFullUrl.path))
    }

    @objc
    func stat(_ path: String, resolver resolve: RCTPromiseResolveBlock,
              rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let url = URL(fileURLWithPath: path)
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
                .localizedNameKey,
                .fileSizeKey,
                .isDirectoryKey
            ])
            let dict = NSMutableDictionary()

            dict["isInICloud"] = resources.isUbiquitousItem
            dict["containerDisplayName"] = resources.ubiquitousItemContainerDisplayName
            dict["isDownloading"] = resources.ubiquitousItemIsDownloading
            // TODO: curious why this is always `false` for calling `download` for a folder, maybe due to files under the folder was not downloaded entirely? have a test when your're free.
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
            dict["fileSize"] = resources.fileSize
            dict["isDirectory"] = resources.isDirectory

            resolve(dict)
        } catch {
            reject("ERR_STAT", error.localizedDescription, NSError(domain: "", code: 0))
        }
    }
}

// MARK: upload, download
extension CloudStoreModule {

    ///  init and start query, when related events triggered then gather info from query
    /// - Parameters:
    ///   - queryCallback: this callback was used to gather data
    private func initAndStartQuery(iCloudURL url: URL, id: String, resolver resolve: @escaping RCTPromiseResolveBlock, using queryCallback: @escaping (_ query: NSMetadataQuery) -> (NSMutableArray,Bool)) {
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
        // We need use `==` here but not `CONTAINS` to fix files with same prefix
        query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemPathKey,url.path)
        // query.predicate = NSPredicate(format: "TRUEPREDICATE", NSMetadataItemPathKey,url.path)
        query.notificationBatchingInterval = 0.2

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidStartGathering, object: query, queue: query.operationQueue, using: { [self] notification in
            Logger.log("start results:\n")
            let (res, ended) = queryCallback(query)
            if ended {
                Logger.log("query stopped on start-phase")
                query.stop()
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidStartGathering, object: query)
            }
            if hasListeners {
                sendEvent(withName: "onICloudDocumentsStartGathering", body: NSDictionary(dictionary: [
                    "id": id,
                    "info": getChangedItems(notification),
                    "detail": res
                ]))
            }
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryGatheringProgress, object: query,  queue: query.operationQueue, using: { [self] notification in
            Logger.log("gather results:\n")
            let (res, ended) = queryCallback(query)
            if ended {
                Logger.log("query stopped on gather-phase")
                query.stop()
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryGatheringProgress, object: query)
            }
            if hasListeners {
                sendEvent(withName: "onICloudDocumentsGathering", body: NSDictionary(dictionary: [
                    "id": id,
                    "info": getChangedItems(notification),
                    "detail": res
                ]))
            }
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query,  queue: query.operationQueue, using: { [self] notification in
            Logger.log("finish results:\n")
            let (res, ended) = queryCallback(query)
            if ended {
                Logger.log("query stopped on finish-phase")
                query.stop()
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query)
            }
            if hasListeners {
                sendEvent(withName: "onICloudDocumentsFinishGathering", body: NSDictionary(dictionary: [
                    "id": id,
                    "info": getChangedItems(notification),
                    "detail": res
                ]))
            }
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidUpdate, object: query,  queue: query.operationQueue, using: {
            [self] notification in
            Logger.log("update results:\n")
            let (res, ended) = queryCallback(query)
            if ended {
                Logger.log("query stopped on update-phase")
                query.stop()
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidUpdate, object: query)
            }
            if hasListeners {
                sendEvent(withName: "onICloudDocumentsUpdateGathering", body: NSDictionary(dictionary: [
                    "id": id,
                    "info": getChangedItems(notification),
                    "detail": res
                ]))
            }
        })

        let _ = query.start()
        resolve(nil)
    }

    private func listenUpload(iCloudURL: URL,id: String, resolver: @escaping RCTPromiseResolveBlock) {
        initAndStartQuery(iCloudURL: iCloudURL,id: id, resolver: resolver) { (query) in
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
                Logger.log(fileItemURL," upload info: uploadProgress-\(String(describing: uploadProgress))")
            }

            let m: NSMutableArray = NSMutableArray()
            m.addObjects(from: arr.map{$0.nsDictionary})
            if !ended {
                query.enableUpdates()
            }
            return (m, ended)
        }
    }

    private func listenDownload(iCloudURL: URL,id: String, resolver: @escaping RCTPromiseResolveBlock) {
        initAndStartQuery(iCloudURL: iCloudURL,id:id, resolver: resolver) { query in
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

                arr.append(ICloudGatheringFile(type: .download, path: fileItemURL.path, progress: downloadingProgress, isDir: isDir))

                // stop query when one file progress is 100
                if downloading == false && downloadingProgress == 100 {
                    ended = true
                }
                Logger.log("download-info:\n","url-\(fileItemURL)\nisDownloading-\(String(describing: downloading))\nstatus-\(String(describing: downloadingStatus))\nprogress-\(String(describing: downloadingProgress))\n")
            }

            if !ended {
                query.enableUpdates()
            }

            let m: NSMutableArray = NSMutableArray()
            m.addObjects(from: arr.map{$0.nsDictionary})
            return (m,ended)
        }
    }

    @objc
    func upload(_ localPath: String, to path: String, with options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock,
                rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let id = (options["id"] as! String)
        let localURL = URL(fileURLWithPath: localPath)
        let iCloudURL = URL(fileURLWithPath: path)

        do {
            try copyItem(at: localURL, to: iCloudURL)
        } catch {
            reject("ERR_COPY_TO_ICLOUD", error.localizedDescription, NSError(domain: "", code: 0))
            return
        }

        listenUpload(iCloudURL: iCloudURL,id: id, resolver: resolve)
    }

    @objc
    func download(_ path: String, with options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock,
                  rejecter reject: RCTPromiseRejectBlock) {
        if(icloudInvalid(then: reject)) {return}

        let id = (options["id"] as! String)
        let pathWithoutDot = (options["pathWithoutDot"] as! String)
        let iCloudURL = URL(fileURLWithPath: pathWithoutDot);

        do {
            try FileManager.default.evictUbiquitousItem(at: iCloudURL)
            // if the url is a directory, this only download the dir itself but not the files under it, you need to recurisvely download files of folders, check https://github.com/farnots/iCloudDownloader/blob/master/iCloudDownlader/Downloader.swift for inspiration
            try FileManager.default.startDownloadingUbiquitousItem(at: iCloudURL)
        } catch {
            reject("ERR_DOWNLOAD_ICLOUD_FILE", error.localizedDescription, NSError(
                domain: "", code: 0))
            return
        }

        listenDownload(iCloudURL: iCloudURL,id:id, resolver: resolve)
    }
}

class Logger {
    public static func log(_ items: Any...) {
#if DEBUG
        print("[cloud-store] ", items)
#endif
    }
}
