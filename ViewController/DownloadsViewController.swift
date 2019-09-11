import UIKit

class DownloadsViewController: BaseViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let presenter: DownloadsPresenterType
    private let analytics: DownloadsAnalyticsType
    private let uiFactory: AppUIFactory

    init(presenter: DownloadsPresenterType,
         analytics: DownloadsAnalyticsType,
         uiFactory: AppUIFactory) {
        self.presenter = presenter
        self.analytics = analytics
        self.uiFactory = uiFactory
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = UITestNodeID.downloadListView
        title = "Загрузки"

        analytics.reportScreenOpening()
        loadData()

        presenter.setup(delegate: self, host: self, tableView: tableView)
    }
    
    private func loadData() {
        presenter.loadDownloads { [weak self] (result) in
            guard let strongSelf = self else { return }
            onMainThread {
                switch result {
                case .success(let viewModel):
                    if viewModel.items.isEmpty {
                        strongSelf.showEmptyState()
                    } else {
                        strongSelf.showSuccessState()
                    }
                case let .failure(error):
                    strongSelf.showErrorState(error)
                }
            }
        }
    }
    
    private func showSuccessState() {
        tableView.isHidden = false
        toSuccessStateView()
    }
    
    private func showEmptyState() {
        tableView.isHidden = true
        toSuccessStateView()
        showEmptyView(inView: view, appUIFactory: uiFactory)
    }
    
    private func showErrorState(_ error: APIError) {
        tableView.isHidden = true
        toErrorStateView(error, appUIFactory: uiFactory) { [weak self] in
            self?.loadData()
        }
    }
}

extension DownloadsViewController: DownloadsPresenterDelegate {
    func downloadsListBecameEmpty() {
        showEmptyState()
    }
}
