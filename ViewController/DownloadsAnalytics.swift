import Foundation

protocol DownloadsAnalyticsType {
    func reportScreenOpening()
}

final class DownloadsAnalytics: DownloadsAnalyticsType {
    private let analytics: Analytics

    init(analytics: Analytics) {
        self.analytics = analytics
    }

    func reportScreenOpening() {
        analytics.reportScreenOpenning("DownloadsView")
    }
}
