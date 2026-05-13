import UIKit

final class DSPInAppDebuggerVC: UIViewController {
    let collectionView: UICollectionView
    let flattenDebugItems: [DSPAnyDebugItem]
    let debuggerItems: [DSPAnyDebugItem]
    let options: [DSPOptions]
    lazy var dataSource: UICollectionViewDiffableDataSource<Section, DSPAnyDebugItem> = {
        preconditionFailure()
    }()

    enum Section: Int, CaseIterable {
        case recent
        case items

        var title: String {
            switch self {
            case .recent:
                return "Recent"
            case .items:
                return "Items"
            }
        }
    }

    init(title: String = "Debug", debuggerItems: [any DSPDebugItem], options: [DSPOptions]) {
        self.options = options
        self.flattenDebugItems = debuggerItems.map(DSPAnyGroupDebugItem.init).flatten()
            .map(DSPAnyDebugItem.init)
        self.debuggerItems = debuggerItems.map(DSPAnyDebugItem.init)
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = .supplementary
        let collectionViewLayout = UICollectionViewCompositionalLayout.list(using: configuration)
        collectionView = UICollectionView(
            frame: .null,
            collectionViewLayout: collectionViewLayout
        )
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        view = collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .always

        search: do {
            let searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            navigationItem.searchController = searchController
        }

        navigation: do {
            let rightItem = UIBarButtonItem(
                systemItem: .done,
                primaryAction: UIAction(handler: { [weak self] (_) in
                    if #available(iOS 15, *) {
                        // sheetPresentationController
                        self?.dismiss(animated: true)
                    } else {
                        // DSPCustomActivityVC
                        self?.parent?.parent?.dismiss(animated: true)
                    }
                }),
                menu: nil
            )
            navigationItem.rightBarButtonItem = rightItem
        }

        toolbar: do {
            let label = UILabel(frame: .null)
            label.font = UIFont.preferredFont(forTextStyle: .caption1)
            label.textColor = UIColor.label
            label.text =
                "\(DSPApplication.current.appName) \(DSPApplication.current.version) (\(DSPApplication.current.build))"
            let bundleIDLabel = UILabel(frame: .null)
            bundleIDLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
            bundleIDLabel.textColor = UIColor.secondaryLabel
            bundleIDLabel.text = "\(DSPApplication.current.bundleIdentifier)"
            let vStack = UIStackView(arrangedSubviews: [label, bundleIDLabel])
            vStack.axis = .vertical
            vStack.alignment = .center
            let space = UIBarButtonItem.flexibleSpace()
            let item = UIBarButtonItem(customView: vStack)
            navigationController?.isToolbarHidden = false
            toolbarItems = [space, item, space]
        }
        configureDataSource()
        collectionView.delegate = self

        performUpdate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        deselectSelectedItems()
    }

    private func onCompleteAction(_ result: DSPDebugSPResult) {
        switch result {
        case .success(let message) where message != nil:
            presentAlert(title: "Success", message: message)
        case .failure(let message) where message != nil:
            presentAlert(title: "Error", message: message)
        default:
            break
        }
    }

    private func deselectSelectedItems(animated: Bool = true) {
        collectionView.indexPathsForSelectedItems?
            .forEach { (indexPath) in
                collectionView.deselectItem(at: indexPath, animated: animated)
            }
    }
}

extension DSPInAppDebuggerVC {

    func configureDataSource() {
        let selectCellRegstration = UICollectionView.CellRegistration {
            (cell: UICollectionViewListCell, indexPath, title: String) in
            var content = cell.defaultContentConfiguration()
            content.text = title
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
        }

        let executableCellRegstration = UICollectionView.CellRegistration {
            (cell: UICollectionViewListCell, indexPath, title: String) in
            var content = cell.defaultContentConfiguration()
            content.text = title
            cell.contentConfiguration = content
        }

        let toggleCellRegstration = UICollectionView.CellRegistration {
            (
                cell: DSPToggleCell,
                indexPath,
                item: (title: String, current: () -> Bool, onChange: (Bool) -> Void)
            ) in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content
            cell.current = item.current
            cell.onChange = item.onChange
        }

        let sliderCellRegstration = UICollectionView.CellRegistration {
            (
                cell: DSPSliderCell,
                indexPath,
                item: (
                    title: String, current: () -> Double, valueLabelText: (Double) -> String,
                    range: ClosedRange<Double>, onChange: (Double) -> Void
                )
            ) in
            cell.title = item.title
            cell.current = item.current
            cell.valueLabelText = item.valueLabelText
            cell.range = item.range
            cell.onChange = item.onChange
        }

        dataSource = .init(
            collectionView: collectionView,
            cellProvider: { [unowned self] (collectionView, indexPath, item) in
                switch item.action {
                case .didSelect:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: selectCellRegstration,
                        for: indexPath,
                        item: item.debugItemTitle
                    )
                case .execute:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: executableCellRegstration,
                        for: indexPath,
                        item: item.debugItemTitle
                    )
                case let .toggle(current, onChange):
                    return collectionView.dequeueConfiguredReusableCell(
                        using: toggleCellRegstration,
                        for: indexPath,
                        item: (
                            item.debugItemTitle, current,
                            { [unowned self] (value) in
                                Task { @MainActor[weak self] in
                                    let result = await onChange(value)
                                    self?.onCompleteAction(result)
                                }
                            }
                        )
                    )
                case let .slider(current, valueLabelText, range, onChange):
                    return collectionView.dequeueConfiguredReusableCell(
                        using: sliderCellRegstration,
                        for: indexPath,
                        item: (
                            item.debugItemTitle, current, valueLabelText, range,
                            { [unowned self] (value) in
                                Task { @MainActor[weak self] in
                                    let result = await onChange(value)
                                    self?.onCompleteAction(result)
                                }
                            }
                        )
                    )
                }
            }
        )

        let headerRegistration = UICollectionView.SupplementaryRegistration<
            UICollectionViewListCell
        >(elementKind: UICollectionView.elementKindSectionHeader) {
            [unowned self] (headerView, elementKind, indexPath) in
            var configuration = headerView.defaultContentConfiguration()
            if #available(iOS 15.0, *) {
                #if compiler(>=5.5)
                configuration.text =
                    self.dataSource.sectionIdentifier(for: indexPath.section)?.title
                #else
                // FIXME: Index is wrong when the recent section is disabled.
                configuration.text = Section(rawValue: indexPath.section)?.title
                #endif
            } else {
                // FIXME: Index is wrong when the recent section is disabled.
                configuration.text = Section(rawValue: indexPath.section)?.title
            }
            headerView.contentConfiguration = configuration
        }
        dataSource.supplementaryViewProvider = {
            (collectionView, kind, indexPath) -> UICollectionReusableView? in
            collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration,
                for: indexPath
            )
        }
    }

    func performUpdate(_ query: String? = nil) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, DSPAnyDebugItem>()

        if let query = query, !query.isEmpty {
            snapshot.appendSections([Section.items])
            let filteredItems = flattenDebugItems.filter({
                $0.debugItemTitle.lowercased().contains(query.lowercased())
            })
            snapshot.appendItems(filteredItems, toSection: .items)
        } else {
            let recentItems = DSPRecentItemStore(items: debuggerItems).get()
            if !recentItems.isEmpty && options.debugSPConfiguration.showsRecentItems {
                snapshot.appendSections([Section.recent])
                snapshot.appendItems(recentItems, toSection: .recent)
            }
            snapshot.appendSections([Section.items])
            snapshot.appendItems(debuggerItems, toSection: .items)
        }

        dataSource.apply(snapshot)
    }
}

extension DSPInAppDebuggerVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section) {
        case .items, .recent:
            let item = dataSource.itemIdentifier(for: indexPath)!
            switch item.action {
            case let .didSelect(action):
                Task { @MainActor[weak self] in
                    guard let self = self else { return }
                    let result = await action(self)
                    self.onCompleteAction(result)
                }
            case let .execute(action):
                Task { @MainActor[weak self] in
                    let result = await action()
                    self?.onCompleteAction(result)
                }
            case .toggle, .slider:
                break
            }
            DSPRecentItemStore(items: debuggerItems).insert(item)
            performUpdate()
        default:
            fatalError()
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath)
        -> Bool
    {
        switch Section(rawValue: indexPath.section) {
        case .items, .recent:
            let item = dataSource.itemIdentifier(for: indexPath)!
            switch item.action {
            case .didSelect, .execute:
                return true
            case .toggle, .slider:
                return false
            }
        default:
            fatalError()
        }
    }

    private func presentAlert(title: String, message: String?) {
        DispatchQueue.main.async { [weak self] in
            let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
            vc.addAction(
                .init(
                    title: "OK",
                    style: .cancel,
                    handler: { [weak self] _ in
                        self?.deselectSelectedItems()
                    }
                )
            )
            self?.present(vc, animated: true, completion: nil)
        }
    }
}

extension DSPInAppDebuggerVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        performUpdate(searchController.searchBar.text)
    }
}

open class DSPCollectionViewCell: UICollectionViewCell {
    open override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                contentView.alpha = 0.5
            } else {
                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?.contentView.alpha = 1.0
                }
            }
        }
    }
}
