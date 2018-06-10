import Eureka

import UIKit

open class _SearchSelectorViewController<Row: SelectableRowType, OptionsRow: OptionsProviderRow>: SelectorViewController<OptionsRow>, UISearchResultsUpdating where Row.Cell.Value: SearchItem {

    let searchController = UISearchController(searchResultsController: nil)

    var originalOptions = [ListCheckRow<Row.Cell.Value>]()
    var currentOptions = [ListCheckRow<Row.Cell.Value>]()

    open override func viewDidLoad() {
        super.viewDidLoad()

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.tintColor = .darkText
        if #available(iOS 11.0, *) {
            if let textfield = searchController.searchBar.value(forKey: "searchField") as? UITextField {
                textfield.textColor = UIColor.darkText
                if let backgroundview = textfield.subviews.first {
                    backgroundview.backgroundColor = UIColor.white
                    backgroundview.layer.cornerRadius = 10
                    backgroundview.clipsToBounds = true
                }
            }
        }
        definesPresentationContext = true

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
    }

    public func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else { return }
        if query.isEmpty {
            currentOptions = originalOptions
        } else {
            currentOptions = originalOptions.filter { $0.selectableValue?.matchesSearchQuery(query) ?? false }
        }
        tableView.reloadData()
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentOptions.count
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = currentOptions[indexPath.row]
        option.updateCell()
        return option.baseCell
    }

    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentOptions[indexPath.row].didSelect()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    open override func setupForm(with options: [OptionsRow.OptionsProviderType.Option]) {
        super.setupForm(with: options)
        if let allRows = form.first?.map({ $0 }) as? [ListCheckRow<Row.Cell.Value>] {
            originalOptions = allRows
            currentOptions = originalOptions
        }
        tableView.reloadData()
    }
}

open class SearchSelectorViewController<OptionsRow: OptionsProviderRow>: _SearchSelectorViewController<ListCheckRow<OptionsRow.OptionsProviderType.Option>, OptionsRow> where OptionsRow.OptionsProviderType.Option: SearchItem {
}

open class _SearchPushRow<Cell: CellType> : SelectorRow<Cell> where Cell: BaseCell, Cell.Value: SearchItem {
    public required init(tag: String?) {
        super.init(tag: tag)
        presentationMode = .show(controllerProvider: ControllerProvider.callback { return SearchSelectorViewController<SelectorRow<Cell>> { _ in } }, onDismiss: { vc in
//            _ = vc.navigationController?.popViewController(animated: true)
        })
    }
}

public final class SearchPushRow<T: Equatable> : _SearchPushRow<PushSelectorCell<T>>, RowType where T: SearchItem {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public protocol SearchItem {
    func matchesSearchQuery(_ query: String) -> Bool
}
