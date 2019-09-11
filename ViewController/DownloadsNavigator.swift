import UIKit

final class DownloadsNavigator: Navigator {
    private let applicationNavigator: ApplicationNavigator
    
    init(applicationNavigator: ApplicationNavigator) {
        self.applicationNavigator = applicationNavigator
    }

    enum Destination {
        case showcase
        case series(String, String?)
        case player(PersistentPlaybackModel)
    }

    func navigate(to dst: Destination, host: UIViewController) {
        switch dst {
        case .showcase:
            applicationNavigator.present(fromHost: host, segue: .showcase(.series), animated: true)
        case let .series(seriesUuid, title):
            applicationNavigator.present(fromHost: host, segue: .ottDownloadSeries(seriesUuid, title), animated: true)
        case .player(let model):
            applicationNavigator.presentModally(fromHost: host,
                                                segue: .offlinePlayer(persistentPlaybackModel: model, sourceScreen: .offline),
                                                animated: true)
        }
    }
}
