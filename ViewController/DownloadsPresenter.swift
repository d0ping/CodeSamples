import Foundation

protocol DownloadsPresenterDelegate: class {
    func downloadsListBecameEmpty()
}

protocol DownloadsPresenterType: class {
    func setup(delegate: DownloadsPresenterDelegate, host: UIViewController, tableView: UITableView)
    func loadDownloads(completion: @escaping (Either<DownloadsViewModel, KPAPIError>) -> Void)
    func emptyStateButtonClicked()
    func navigate(to: DownloadsNavigator.Destination)
}

final class DownloadsPresenter: DownloadsPresenterType {
    private let navigator: DownloadsNavigator
    private let interactor: DownloadsInteractorType
    private let builder: DownloadsViewModelBuilderType
    private let adapter: EditingTableAdapterType

    private weak var delegate: DownloadsPresenterDelegate?
    private weak var hostViewController: UIViewController?
    
    private var viewModel: DownloadsViewModel?
    
    init(navigator: DownloadsNavigator,
         interactor: DownloadsInteractorType,
         builder: DownloadsViewModelBuilderType,
         adapter: EditingTableAdapterType) {
        self.navigator = navigator
        self.interactor = interactor
        self.builder = builder
        self.adapter = adapter
    }

    func setup(delegate: DownloadsPresenterDelegate, host: UIViewController, tableView: UITableView) {
        self.delegate = delegate
        self.hostViewController = host
        setupTableView(tableView)
        configureInteractor()
    }
    
    func loadDownloads(completion: @escaping (Either<DownloadsViewModel, KPAPIError>) -> Void) {
        onBackgroundThread { [weak self] in
            guard let strongSelf = self else { return }
            let viewModel = strongSelf.builder.build(from: strongSelf.interactor.allAssets())
            strongSelf.viewModel = viewModel
            onMainThread {
                strongSelf.adapter.apply(viewModels: [viewModel.items])
                strongSelf.adapter.reload()
                completion(.success(viewModel))
            }
        }
    }
    
    private func setupTableView(_ tableView: UITableView) {
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 112
        
        adapter.add(interpreter: makeAssetInterpreter())
        adapter.bind(tableView: tableView)
    }
    
    private func configureInteractor() {
        interactor.stateChangedClosure = { [weak self] uuid, state in
            guard let strongSelf = self else { return }
            guard let viewModel = strongSelf.viewModel else { return }
            guard let index = viewModel.items.firstIndex(where: { model in
                guard let model = model as? DownloadItemCellViewModel else { return false }
                return model.asset.uuid == uuid
            }) else { return }
            guard let cellModel = viewModel.items[index] as? DownloadItemCellViewModel else { return }
            
            viewModel.items[index] = strongSelf.builder.updatedViewModel(cellModel, state: state)
           
            onMainThread {
                strongSelf.adapter.apply(viewModels: [viewModel.items])
                strongSelf.adapter.reloadItemIfNeeded(at: IndexPath(row: index, section: 0))
            }
        }
    }

    func emptyStateButtonClicked() {
        navigate(to: .showcase)
    }

    func navigate(to: DownloadsNavigator.Destination) {
        if let host = hostViewController {
            navigator.navigate(to: to, host: host)
        }
    }
    
    private func deleteItemIfNeeded(at indexPath: IndexPath) {
        guard let cellModel = viewModel?.items[indexPath.row] as? DownloadItemCellViewModel else { return }
        
        interactor.deleteAssets(uuids: [cellModel.asset.uuid])
        adapter.deleteItem(at: indexPath, with: .fade)
        
        guard let viewModel = viewModel else { return }
        viewModel.items.remove(at: indexPath.row)
        if viewModel.items.isEmpty {
            delegate?.downloadsListBecameEmpty()
        }
    }
}

extension DownloadsPresenter {
    private func makeAssetInterpreter() -> TableCellInterpreterType {
        let interpreter = EditingTableCellInterpreter<DownloadItemTableViewCell, DownloadItemCellViewModel>()
        interpreter.dequeue = { cell, vm in
            cell.setup(vm: vm)
        }
        interpreter.onSelect = { [weak self] indexPath, vm in
            guard let strongSelf = self else { return }
            if vm.asset.isSeries {
                strongSelf.navigate(to: .series(vm.asset.uuid, vm.asset.title))
            } else {
                guard let asset = strongSelf.interactor.downloadedAsset(uuid: vm.asset.uuid) else { return }
                guard let playbackModel = PersistentPlaybackModel(asset: asset) else { return }
                strongSelf.navigate(to: .player(playbackModel))
            }
        }
        interpreter.onDelete = { [weak self] indexPath in
            self?.deleteItemIfNeeded(at: indexPath)
        }
        return interpreter
    }
}
