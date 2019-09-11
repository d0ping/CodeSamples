import Foundation

protocol DownloadsViewModelBuilderType: class {
    func build(from downloads: [AssetInfoModel]) -> DownloadsViewModel
    func updatedViewModel(_ cellModel: EpisodeOfflineCellViewModel, state: EpisodeDownloadState) -> EpisodeOfflineCellViewModel
}

final class DownloadsViewModel {
    var items: [SimpleTableViewModelType]
    
    init(items: [SimpleTableViewModelType]) {
        self.items = items
    }
}

final class DownloadsViewModelBuilder: DownloadsViewModelBuilderType {
    private let cellBuilder: DownloadItemCellViewModelBuilderType
    
    init(cellBuilder: DownloadItemCellViewModelBuilderType) {
        self.cellBuilder = cellBuilder
    }
    
    func build(from downloads: [AssetInfoModel]) -> DownloadsViewModel {
        return DownloadsViewModel(items: cellBuilder.build(downloads))
    }
    
    func updatedViewModel(_ cellModel: DownloadItemCellViewModel, state: DownloadState) -> DownloadItemCellViewModel {
        return cellBuilder.updatedViewModel(cellModel, state: state)
    }
}
