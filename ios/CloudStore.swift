import Foundation
import Combine

extension String {
    func rmPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

@objc(CloudStoreModule)
class CloudStoreModule : RCTEventEmitter {
    private let domain = "iCloudModule"
    private var hasListeners = false
    private var iCloudURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)
    }
    private var subscriberContainer = Set<AnyCancellable>()
    private var queryContainer = Set<NSMetadataQuery>()

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

    private func getFullICloudURL(_ relativePath: String, isDirectory dir: Bool = false) -> URL  {
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
    func writeFile(_ relativeFilePath: String, withContent content: String, withOptions options: NSDictionary,resolver resolve: RCTPromiseResolveBlock,
                   rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil: reject) else { return }

        let override: Bool = (options["override"] as? Bool) ?? false
        let fileURL = getFullICloudURL(relativeFilePath)

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

        let fileURL = getFullICloudURL(relativeFilePath)
        if(!FileManager.default.fileExists(atPath: fileURL.path)) {
            reject("ERR_FILE_NOT_EXISTS", "file \(fileURL.path) not exists", NSError(domain: domain, code: 401, userInfo: nil))
            return
        }

        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            resolve(content)
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

        let dirURL = getFullICloudURL(relativePath)

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
        let url = getFullICloudURL(relativePath, isDirectory: true)
        createDirIfNotExists(url, ifFail: reject)
        resolve(nil)
    }

    @objc
    func moveDir(_ relativeFromPath: String, to relativeToPath: String, resolver resolve: RCTPromiseResolveBlock,
                 rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil: reject) else { return }
        do {
            let srcDirURL = getFullICloudURL(relativeFromPath)
            let destDirURL = getFullICloudURL(relativeToPath)
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
// https://stackoverflow.com/questions/39176196/how-to-provide-a-localized-description-with-an-error-type-in-swift
enum MyError: LocalizedError {
    case notExists(path: String)

    public var errorDescription: String? {
        switch self {
        case .notExists(let path):
            return "dest folder \"\(path)\" not exists, you need create it first"
        }
    }
}
// MARK: file or dir
extension CloudStoreModule {
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
    func copy(_ srcRelativePath: String, to destRelativePath: String,  with options: NSDictionary, resolver resolve: RCTPromiseResolveBlock,
              rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil:reject) else { return }

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

        let url = getFullICloudURL(relativePath, isDirectory: relativePath.hasSuffix("/"))
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

        let fileFullUrl = getFullICloudURL(relativePath)
        resolve(FileManager.default.fileExists(atPath: fileFullUrl.path))
    }
    
    @objc
    func stat(_ relativePath: String, resolver resolve: RCTPromiseResolveBlock,
                  rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil:reject) else { return }

        let url = getFullICloudURL(relativePath)
        if(!FileManager.default.fileExists(atPath: url.path)) {
            reject("ERR_NOT_EXISTS", "file \(url.path) not exists", NSError(domain: domain, code: 401, userInfo: nil))
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

            resolve(dict)
        } catch {
            reject("ERR_STAT", error.localizedDescription, NSError(domain: domain, code: 402, userInfo: nil))
        }
    }
    

    private func initAndStartQuery(iCloudURL url: URL, resolver resolve: @escaping RCTPromiseResolveBlock, using enumQuery: @escaping (_ query: NSMetadataQuery) -> (NSMutableArray,Bool)) {
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

        // TODO: we use publisher here is for future JSI to better support such as upload('/path',{ onProgress: fn, onError: fn}) instead of listening global listeners

        var startSub: AnyCancellable?
        startSub = NotificationCenter.default.publisher(for: NSNotification.Name.NSMetadataQueryDidStartGathering, object: query).prefix(1).sink{ [self] n in
            print("☹️start results:")

            let (res, _) = enumQuery(query)
            if hasListeners {
                sendEvent(withName: "onICloudDocumentsStartGathering", body: NSDictionary(dictionary: [
                    "info": getChangedItems(n),
                    "detail": res
                ]))
            }
        }
        startSub?.store(in: &subscriberContainer)

        var gatherSub: AnyCancellable?
        gatherSub = NotificationCenter.default.publisher(for: NSNotification.Name.NSMetadataQueryGatheringProgress, object: query).prefix(1).sink{ [self] n in
            print("😑gather results:")
            let (res, _) = enumQuery(query)

            if hasListeners {
                sendEvent(withName: "onICloudDocumentsGathering", body: NSDictionary(dictionary: [
                    "info": getChangedItems(n),
                    "detail": res
                ]))
            }
        }
        gatherSub?.store(in: &subscriberContainer)

        var finishSub: AnyCancellable?
        finishSub = NotificationCenter.default.publisher(for: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query).prefix(1).sink{ [self] n in
            print("😶finish results:")

            let (res, _) = enumQuery(query)
            if hasListeners {
                sendEvent(withName: "onICloudDocumentsFinishGathering", body: NSDictionary(dictionary: [
                    "info": getChangedItems(n),
                    "detail": res
                ]))
            }
        }
        finishSub?.store(in: &subscriberContainer)

        var updateSub: AnyCancellable?
        updateSub = NotificationCenter.default.publisher(for: NSNotification.Name.NSMetadataQueryDidUpdate, object: query).sink{ [self] n in
            print("🤠update results:")

            let (res, ended) = enumQuery(query)
            if ended {
                print("persist query stopped")
                query.stop()
                updateSub?.cancel()
                queryContainer.remove(query)
            }
            if hasListeners {
                sendEvent(withName: "onICloudDocumentsUpdateGathering", body: NSDictionary(dictionary: [
                    "info": getChangedItems(n),
                    "detail": res
                ]))
            }
        }
        updateSub?.store(in: &subscriberContainer)

        queryContainer.insert(query)
        let _ = query.start()
        resolve(nil)
    }

    @objc
    func upload(_ fullLocalPath: String, to relativePath: String, resolver resolve: @escaping RCTPromiseResolveBlock,
                rejecter reject: RCTPromiseRejectBlock) {
        guard assertICloud(ifNil: reject) else { return }
        let localURL = URL(string: fullLocalPath)
        guard let localURL = localURL else {
            reject("ERR_INVALID_PATH", "local path \"\(fullLocalPath)\" is invalid", NSError(domain: domain, code: 801, userInfo: nil))
            return
        }
        let iCloudURL = getFullICloudURL(relativePath)

        do {
            try copyItem(at: localURL, to: iCloudURL)
        } catch {
            reject("ERR_COPY_TO_ICLOUD", error.localizedDescription, NSError(domain: domain, code: 304, userInfo: nil))
            return
        }

        initAndStartQuery(iCloudURL: iCloudURL, resolver: resolve) { (query) in
            query.disableUpdates()

            var arr: [ICloudGatheringFile] = []
            var ended = false
            for item in query.results {
                let item = item as! NSMetadataItem
                let fileItemURL = item.value(forAttribute: NSMetadataItemURLKey) as! URL
                let isDir = try? fileItemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory
                let uploadProgress = item.value(forAttribute: NSMetadataUbiquitousItemPercentUploadedKey) as? Float
                arr.append(ICloudGatheringFile(type: .upload, path: fileItemURL.path, progress: uploadProgress, isDir: isDir))
                if uploadProgress == 100 {

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
        guard assertICloud(ifNil: reject) else { return }
        let iCloudURL = getFullICloudURL(relativePath)

        do {
            // TODO: if url is a directory, this only download dir but not files under it, need to manually handle it, check https://github.com/farnots/iCloudDownloader/blob/master/iCloudDownlader/Downloader.swift for inspiration
            try FileManager.default.startDownloadingUbiquitousItem(at: iCloudURL)
        } catch {
            reject("ERR_DOWNLOAD_ICLOUD_FILE", error.localizedDescription, NSError(
                domain: domain, code: 801, userInfo: nil))
            return
        }

        initAndStartQuery(iCloudURL: iCloudURL, resolver: resolve) { query in
            query.disableUpdates()
            var arr: [ICloudGatheringFile] = []
            var ended = false
            for item in query.results {
                let item = item as! NSMetadataItem
                let fileItemURL = item.value(forAttribute: NSMetadataItemURLKey) as! URL

                let isDir = try? fileItemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? nil
                let downloadingProgress = item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey) as? Float
                let downloadingStatus = item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey)
                let downloading = item.value(forAttribute: NSMetadataUbiquitousItemIsDownloadingKey)

                arr.append(ICloudGatheringFile(type: .persist, path: fileItemURL.path, progress: downloadingProgress, isDir: isDir))

                // stop query when one file progress is 100
                if downloadingProgress == 100 {
                    ended = true
                }
                print(fileItemURL," download info: isDownloading-\(String(describing: downloading)),status-\(String(describing: downloadingStatus)),progress-\(String(describing: downloadingProgress))")
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

