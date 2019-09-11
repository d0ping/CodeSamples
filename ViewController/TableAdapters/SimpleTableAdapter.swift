import Foundation
import UIKit

protocol SimpleTableViewModelType { }

protocol TableCellInterpreterType {
    var cellType: UITableViewCell.Type { get }
    var viewModelType: SimpleTableViewModelType.Type { get }
    
    func dequeue(cell: UITableViewCell, vm: SimpleTableViewModelType)
    func onSelect(indexPath: IndexPath, vm: SimpleTableViewModelType)
    func cellHeight() -> CGFloat
}

protocol SimpleTableAdapterType: class {
    func bind(tableView: UITableView?)
    func apply(viewModels: [[SimpleTableViewModelType]])
    func add(interpreter: TableCellInterpreterType)
    func reload()
    func reloadItemIfNeeded(at indexPath: IndexPath)
    func scrollTo(indexPath: IndexPath, animated: Bool)
    func repeatLastSelectIndexPath()
    func deleteItem(at indexPath: IndexPath, with rowAnimation: UITableView.RowAnimation)
}


class TableCellInterpreter<Cell: UITableViewCell, ViewModel: SimpleTableViewModelType>: TableCellInterpreterType {
    var cellType: UITableViewCell.Type = Cell.self
    var viewModelType: SimpleTableViewModelType.Type = ViewModel.self

    var dequeue: ((Cell, ViewModel) -> Void)?
    var onSelect: ((IndexPath, ViewModel) -> Void)?
    var calculateCellHeight: (() -> CGFloat) = { return UITableView.automaticDimension }

    func dequeue(cell: UITableViewCell, vm: SimpleTableViewModelType) {
        guard let vm = vm as? ViewModel else { return }
        guard let cell = cell as? Cell else { return }

        dequeue?(cell, vm)
    }

    func onSelect(indexPath: IndexPath, vm: SimpleTableViewModelType) {
        guard let vm = vm as? ViewModel else { return }
        onSelect?(indexPath, vm)
    }

    func cellHeight() -> CGFloat {
        return calculateCellHeight()
    }
}

class SimpleTableAdapter: NSObject, SimpleTableAdapterType {
    private var interpreters: [String: TableCellInterpreterType] = [:]
    private var viewModels: [[SimpleTableViewModelType]] = []
    private var lastSelectedIndexPath: IndexPath?

    private weak var tableView: UITableView? {
        willSet {
            tableView?.dataSource = nil
            tableView?.delegate = nil
        }
        didSet {
            guard let tableView = tableView else { return }
            registerAllInterpreters(tableView: tableView)
            tableView.dataSource = self
            tableView.delegate = self
        }
    }

    func bind(tableView: UITableView?) {
        self.tableView = tableView
    }

    func add(interpreter: TableCellInterpreterType) {
        let key = String(describing: interpreter.viewModelType)
        interpreters[String(describing: key)] = interpreter
        tableView?.register(nibWithCellClass: interpreter.cellType)
    }

    func apply(viewModels: [[SimpleTableViewModelType]]) {
        self.viewModels = viewModels
    }

    func reload() {
        tableView?.reloadData()
    }
    
    func reloadItemIfNeeded(at indexPath: IndexPath) {
        guard let cell = tableView?.cellForRow(at: indexPath) else { return }
        guard let vm = viewModel(at: indexPath) else { return }
        
        let interpreter = cellInterpreter(for: vm)
        interpreter.dequeue(cell: cell, vm: vm)
    }

    func scrollTo(indexPath: IndexPath, animated: Bool) {
        guard let tableView = tableView else { return }
        guard tableView.numberOfSections > indexPath.section
         && tableView.numberOfRows(inSection: indexPath.section) > indexPath.row else { return }
        
        tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
    }

    func repeatLastSelectIndexPath() {
        guard let tableView = tableView, let indexPath = lastSelectedIndexPath else { return }
        self.tableView(tableView, didSelectRowAt: indexPath)
    }
    
    func deleteItem(at indexPath: IndexPath, with rowAnimation: UITableView.RowAnimation) {
        guard let tableView = tableView else { return }
        guard tableView.numberOfSections > indexPath.section
            && tableView.numberOfRows(inSection: indexPath.section) > indexPath.row else { return }
        
        viewModels[indexPath.section].remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: rowAnimation)
    }
}

extension SimpleTableAdapter: UITableViewDataSource, UITableViewDelegate {
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel(at: indexPath) else { return UITableViewCell() }
        let interpreter = cellInterpreter(for: vm)
        let cell = tableView.dequeueReusableCell(withClass: interpreter.cellType, for: indexPath)
        interpreter.dequeue(cell: cell, vm: vm)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let vm = viewModel(at: indexPath) {
            let interpreter = cellInterpreter(for: vm)
            interpreter.onSelect(indexPath: indexPath, vm: vm)
        }
        lastSelectedIndexPath = indexPath
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let vm = viewModel(at: indexPath) else { return tableView.estimatedRowHeight }
        let interpreter = cellInterpreter(for: vm)
        return interpreter.cellHeight()
    }
}

extension SimpleTableAdapter {
    internal func cellInterpreter(at indexPath: IndexPath) -> TableCellInterpreterType? {
        guard let vm = viewModel(at: indexPath) else { return nil }
        return cellInterpreter(for: vm)
    }
    
    private func cellInterpreter(for vm: SimpleTableViewModelType) -> TableCellInterpreterType {
        let key = String(describing: type(of: vm))
        guard let interpreter = interpreters[key] else { fatalError("where is factory?") }
        return interpreter
    }

    private func viewModel(at indexPath: IndexPath) -> SimpleTableViewModelType? {
        guard viewModels.count > indexPath.section
            && viewModels[indexPath.section].count > indexPath.row else { return nil }
        return viewModels[indexPath.section][indexPath.row]
    }
}

extension SimpleTableAdapter {
    private func registerAllInterpreters(tableView: UITableView) {
        interpreters.values.forEach {
            tableView.register(nibWithCellClass: $0.cellType)
        }
    }
}
