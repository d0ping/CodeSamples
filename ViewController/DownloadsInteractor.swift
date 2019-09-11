import Foundation

typealias DownloadStateChangedClosure = (_ uuid: String, _ state: DownloadState) -> Void

protocol DownloadsInteractorType: class {
    var stateChangedClosure: DownloadStateChangedClosure? { get set }
    func allAssets() -> [AssetInfoModel]
    func episodesAssets(seriesUuid: String) -> [AssetInfoModel]
    func deleteAssets(uuids: [String])
    func downloadedAsset(uuid: String) -> AssetInfoModel?
}

final class DownloadsInteractor: DownloadsInteractorType {
    private let downloadsService: DownloadsServiceType
    var stateChangedClosure: DownloadStateChangedClosure?
    
    init(downloadsService: DownloadsServiceType) {
        self.downloadsService = downloadsService
        self.downloadsService.addObserver(self)
    }
    
    func allAssets() -> [AssetInfoModel] {
        return downloadsService.allAssets()
    }
    
    func episodesAssets(seriesUuid: String) -> [AssetInfoModel] {
        return downloadsService.episodesAssets(seriesUuid: seriesUuid)
    }
    
    func deleteAssets(uuids: [String]) {
		uuids.forEach { downloadsService.cancelAndDeleteDownload(uuid: $0) }
    }
    
    func downloadedAsset(uuid: String) -> AssetInfoModel? {
        return downloadsService.readyToPlayAsset(uuid: uuid)
    }
}

extension DownloadsInteractor: DownloadsServiceObserver {
    internal func applyDownloadStateIfNeeded(_ uuid: String, _ state: DownloadState) {
        guard let closure = stateChangedClosure else { return }
        onMainThread { closure(uuid, state) }
    }
}
