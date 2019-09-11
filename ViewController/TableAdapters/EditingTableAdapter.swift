import Foundation

protocol EditingTableCellInterpreterType: class {
    var onDelete: ((IndexPath) -> Void)? { get set }
}

class EditingTableCellInterpreter<Cell: UITableViewCell, ViewModel: SimpleTableViewModelType>: TableCellInterpreter<Cell, ViewModel>, EditingTableCellInterpreterType {
    var onDelete: ((IndexPath) -> Void)?
}

protocol EditingTableAdapterType: SimpleTableAdapterType { }

class EditingTableAdapter: SimpleTableAdapter, EditingTableAdapterType {
    private let editButtonWidth: CGFloat = 74
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var actions: [UITableViewRowAction] = []
        guard let interpreter = cellInterpreter(at: indexPath) as? EditingTableCellInterpreterType else { return actions }
        
        if let onDelete = interpreter.onDelete {
            let delete = UITableViewRowAction(style: .destructive, title: nil) { _, indexPath in
                onDelete(indexPath)
            }
            if let sourceImage = UIImage(named: "DownloadDelete") {
                let image = UIImage.imageOnCanvas(sourceImage,
                                                  size: CGSize(width: tableView.width, height: tableView.estimatedRowHeight),
                                                  center: CGPoint(x: editButtonWidth / 2, y: tableView.estimatedRowHeight / 2),
                                                  color: UIColor.Control.destructive)
                delete.backgroundColor = UIColor(patternImage: image)
            }
            actions.append(delete)
        }
        return actions
    }
}
