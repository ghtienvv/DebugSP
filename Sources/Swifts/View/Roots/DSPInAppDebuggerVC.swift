import UIKit

final class DSPInAppDebuggerVC: UIViewController {
    let collectionView: UICollectionView
    let customDebuggerItems: [any DSPDebugItem]
    let options: [DSPOptions]
    let showsDefaultSection: Bool
    var flattenDebugItems: [DSPAnyDebugItem] = []
    var debuggerItems: [DSPAnyDebugItem] = []
    lazy var dataSource: UICollectionViewDiffableDataSource<Section, DSPAnyDebugItem> = {
        preconditionFailure()
    }()

    struct Section: Hashable {
        let id: String
        let title: String
        let showsSettingsButton: Bool
    }

    static let defaultSection = Section(
        id: "default",
        title: DSPDefaultDebugMenu.sectionTitle,
        showsSettingsButton: true
    )
    static let itemsSection = Section(id: "items", title: "Items", showsSettingsButton: false)

    private func section(for title: String) -> Section {
        Section(id: "section.\(title)", title: title, showsSettingsButton: false)
    }

    init(
        title: String = "Debug",
        debuggerItems: [any DSPDebugItem],
        options: [DSPOptions],
        showsDefaultSection: Bool = true
    ) {
        self.customDebuggerItems = debuggerItems
        self.options = options
        self.showsDefaultSection = showsDefaultSection
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
            [unowned self] (cell: UICollectionViewListCell, _: IndexPath, item: DSPAnyDebugItem) in
            var content = cell.defaultContentConfiguration()
            self.configureContent(&content, with: item)
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
        }

        let executableCellRegstration = UICollectionView.CellRegistration {
            [unowned self] (cell: UICollectionViewListCell, _: IndexPath, item: DSPAnyDebugItem) in
            var content = cell.defaultContentConfiguration()
            self.configureContent(&content, with: item)
            cell.contentConfiguration = content
        }

        let toggleCellRegstration = UICollectionView.CellRegistration {
            (
                cell: DSPToggleCell,
                _: IndexPath,
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
                _: IndexPath,
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
            cellProvider: { [unowned self] collectionView, indexPath, item in
                switch item.action {
                case .didSelect:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: selectCellRegstration,
                        for: indexPath,
                        item: item
                    )
                case .execute:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: executableCellRegstration,
                        for: indexPath,
                        item: item
                    )
                case let .toggle(current, onChange):
                    return collectionView.dequeueConfiguredReusableCell(
                        using: toggleCellRegstration,
                        for: indexPath,
                        item: (
                            item.debugItemTitle, current,
                            { [unowned self] value in
                                Task { @MainActor [weak self] in
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
                            { [unowned self] value in
                                Task { @MainActor [weak self] in
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
            DSPDebugSectionHeaderView
        >(elementKind: UICollectionView.elementKindSectionHeader) {
            [unowned self] headerView, _, indexPath in
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else {
                return
            }
            headerView.apply(
                title: section.title,
                buttonImageName: section.showsSettingsButton ? "gearshape.fill" : nil,
                action: section.showsSettingsButton ? { [weak self] in
                    self?.presentDefaultSettings()
                } : nil
            )
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration,
                for: indexPath
            )
        }
    }

    private func reloadDebuggerItems() {
        let resolvedItems = (showsDefaultSection ? DSPDefaultDebugMenu.visibleItems() : []) + customDebuggerItems
        debuggerItems = resolvedItems.map(DSPAnyDebugItem.init)
        flattenDebugItems = resolvedItems.map(DSPAnyGroupDebugItem.init).flatten().map(DSPAnyDebugItem.init)
    }

    private func configureContent(
        _ content: inout UIListContentConfiguration,
        with item: DSPAnyDebugItem
    ) {
        content.text = item.debugItemTitle
        if let systemImageName = item.debugItemSystemImageName {
            content.image = UIImage(systemName: systemImageName)
        }
    }

    func performUpdate(_ query: String? = nil) {
        reloadDebuggerItems()
        var snapshot = NSDiffableDataSourceSnapshot<Section, DSPAnyDebugItem>()

        if let query = query, !query.isEmpty {
            snapshot.appendSections([Self.itemsSection])
            let filteredItems = flattenDebugItems.filter({
                $0.debugItemTitle.lowercased().contains(query.lowercased())
            })
            snapshot.appendItems(filteredItems, toSection: Self.itemsSection)
        } else {
            if showsDefaultSection {
                snapshot.appendSections([Self.defaultSection])
                let defaultItems = debuggerItems.filter({
                    $0.debugItemSectionTitle == Self.defaultSection.title
                })
                if !defaultItems.isEmpty {
                    snapshot.appendItems(defaultItems, toSection: Self.defaultSection)
                }
            }

            let pinnedSectionTitles = debuggerItems.compactMap(\.debugItemSectionTitle)
                .reduce(into: [String]()) { result, title in
                    guard title != Self.defaultSection.title, !result.contains(title) else { return }
                    result.append(title)
                }
            for title in pinnedSectionTitles {
                let section = section(for: title)
                let items = debuggerItems.filter({ $0.debugItemSectionTitle == title })
                guard !items.isEmpty else { continue }
                snapshot.appendSections([section])
                snapshot.appendItems(items, toSection: section)
            }

            let regularItems = debuggerItems.filter({ $0.debugItemSectionTitle == nil })
            if !regularItems.isEmpty {
                snapshot.appendSections([Self.itemsSection])
                snapshot.appendItems(regularItems, toSection: Self.itemsSection)
            }
        }

        dataSource.apply(snapshot)
    }

    private func presentDefaultSettings() {
        let controller = DSPDefaultDebugSettingsVC { [weak self] in
            self?.performUpdate(self?.navigationItem.searchController?.searchBar.text)
        }
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .pageSheet
        if #available(iOS 15, *) {
            navigationController.sheetPresentationController?.detents = [.medium(), .large()]
            navigationController.sheetPresentationController?.selectedDetentIdentifier = .medium
            navigationController.sheetPresentationController?.prefersGrabberVisible = true
        }
        present(navigationController, animated: true)
    }
}

extension DSPInAppDebuggerVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if dataSource.sectionIdentifier(for: indexPath.section) != nil {
            let item = dataSource.itemIdentifier(for: indexPath)!
            switch item.action {
            case let .didSelect(action):
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    let result = await action(self)
                    self.onCompleteAction(result)
                }
            case let .execute(action):
                Task { @MainActor [weak self] in
                    let result = await action()
                    self?.onCompleteAction(result)
                }
            case .toggle, .slider:
                break
            }
            performUpdate()
        } else {
            fatalError()
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath)
        -> Bool
    {
        if dataSource.sectionIdentifier(for: indexPath.section) != nil {
            let item = dataSource.itemIdentifier(for: indexPath)!
            switch item.action {
            case .didSelect, .execute:
                return true
            case .toggle, .slider:
                return false
            }
        } else {
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

private final class DSPDebugSectionHeaderView: UICollectionReusableView {
    private let titleLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let stackView = UIStackView()
    private let trailingSpacer = UIView()
    private var action: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        actionButton.addAction(UIAction { [weak self] _ in
            self?.action?()
        }, for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.setContentHuggingPriority(.required, for: .horizontal)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(actionButton)
        stackView.addArrangedSubview(trailingSpacer)

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            actionButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func apply(title: String, buttonImageName: String?, action: (() -> Void)?) {
        titleLabel.text = title
        self.action = action
        if let buttonImageName {
            actionButton.isHidden = false
            var configuration = UIButton.Configuration.filled()
            configuration.baseBackgroundColor = .systemBlue
            configuration.baseForegroundColor = .white
            configuration.cornerStyle = .capsule
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 10)
            configuration.image = UIImage(
                systemName: buttonImageName,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
            )
            configuration.imagePadding = 4
            configuration.attributedTitle = AttributedString(
                "Add or Remove",
                attributes: AttributeContainer([
                    .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                    .foregroundColor: UIColor.white,
                ])
            )
            actionButton.configuration = configuration
        } else {
            actionButton.isHidden = true
            actionButton.configuration = nil
            actionButton.setImage(nil, for: .normal)
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
