import Foundation

protocol DownloadsCellViewModelBuilderType: class {
    func build(_ downloads: [AssetInfoModel]) -> [DownloadItemCellViewModel]
    func updatedViewModel(_ cellModel: DownloadItemCellViewModel, state: DownloadState) -> DownloadItemCellViewModel
}

final class DownloadsCellViewModelBuilder: DownloadsCellViewModelBuilderType {
    private let statusBuilder: DownloadsStatusBuilderType
    private let periodFormatter: PeriodFormatterType
    
    init(statusBuilder: DownloadsStatusBuilderType, periodFormatter: PeriodFormatterType) {
        self.statusBuilder = statusBuilder
        self.periodFormatter = periodFormatter
    }
    
    func build(_ downloads: [AssetInfoModel]) -> [DownloadItemCellViewModel] {
        return downloads.map { makeEpisodeCellViewModel(from: $0) } .compactMap { $0 }
    }
    
    func updatedViewModel(_ cellModel: DownloadItemCellViewModel, state: DownloadState) -> DownloadItemCellViewModel {
        return DownloadItemCellViewModel(item: makeEpisodeItemViewModel(from: cellModel.asset, state: state),
                                           asset: cellModel.asset,
                                           state: state)
    }
    
    private func makeEpisodeCellViewModel(from asset: AssetInfoModel) -> DownloadItemCellViewModel {
        let state = statusBuilder.currentDownloadState(asset: asset)
        let assetVM = makeAssetInfoViewModel(from: asset)
        return DownloadItemCellViewModel(item: makeEpisodeItemViewModel(from: assetVM, state: state),
                                           asset: assetVM,
                                           state: state)
    }
    
    private func makeEpisodeItemViewModel(from asset: AssetInfoViewModel, state: DownloadState) -> EpisodeItemViewModel {
        return EpisodeItemViewModel(title: episodeTitle(asset: asset),
                                    secondTitle: asset.originalTitle,
                                    thirdTitle: statusBuilder.localizedDescription(state),
                                    releaseDate: asset.releaseDate)
    }
    
    private func makeAssetInfoViewModel(from asset: AssetInfoModel) -> AssetInfoViewModel {
        return AssetInfoViewModel(uuid: asset.uuid,
                                  kpId: asset.kpId,
                                  isSeries: asset.type == .series,
                                  title: asset.title,
                                  originalTitle: asset.originalTitle,
                                  posterURL: asset.imageRemoteURL,
                                  storedPosterURI: asset.imageFileURL,
                                  episodeNumber: asset.episodeNumber,
                                  seasonNumber: asset.seasonNumber,
                                  seriesUuid: asset.seriesUuid,
                                  episodes: asset.episodes.map({ makeAssetInfoViewModel(from: $0) }),
                                  assetLocationURI: asset.playbackInfo?.assetLocationURI,
                                  assetByteCount: 0,
                                  progress: Float(asset.playbackInfo?.watchProgressPosition ?? 0),
                                  duration: ottPeriodFormatter.format(duration: Int(asset.playbackInfo?.duration ?? 0)),
                                  releaseDate: nil)
    }
    
    private func episodeTitle(asset: AssetInfoViewModel) -> String {
        guard let episodeNumber = asset.episodeNumber else { return asset.title.isEmpty == false ? asset.title : "Эпизод" }
        if asset.title.isEmpty == false {
            return "\(episodeNumber). \(asset.title)"
        }
        return "\(episodeNumber) серия"
    }
}
