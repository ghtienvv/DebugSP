import Combine
import UIKit

class DSPWidgetView: UIVisualEffectView {
    private let defaultEffect = UIBlurEffect(style: .systemMaterialDark)
    private let headerView: UIView = .init(frame: .null)
    private let closeButton: UIButton = .init(type: .system)
    private let expandCollapseButton: UIButton = .init(type: .system)
    private let tableView: UITableView = .init(frame: .null, style: .plain)
    private var cancellables: Set<AnyCancellable> = []
    private var dashboardItems: [any DSPDashboardItem]
    private var configuration: DSPOptions.Widget?
    private var isExpanded: Bool = false
    private var isMonitoring: Bool = false
    private let headerHeight: CGFloat = 36
    private let widgetMargin: CGFloat = 16
    private let tableBottomPadding: CGFloat = 20
    var onRequestClose: (() -> Void)?

    init(dashboardItems: [any DSPDashboardItem], configuration: DSPOptions.Widget?) {
        self.dashboardItems = dashboardItems
        self.configuration = configuration
        super.init(effect: defaultEffect)
        frame = configuration?.frame ?? DSPOptions.Widget.defaultFrame

        let stackView = UIStackView(arrangedSubviews: [headerView, tableView])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.heightAnchor.constraint(equalToConstant: headerHeight)
        ])

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        
        closeButton.addAction(
            .init(handler: { [weak self] _ in
                self?.onRequestClose?()
            }),
            for: .touchUpInside
        )
        headerView.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalToConstant: 18),
            closeButton.heightAnchor.constraint(equalToConstant: 18),
        ])

        expandCollapseButton.translatesAutoresizingMaskIntoConstraints = false
        expandCollapseButton.tintColor = .white
        expandCollapseButton.addAction(
            .init(handler: { [weak self] _ in
                self?.toggleExpandedState()
            }),
            for: .touchUpInside
        )
        headerView.addSubview(expandCollapseButton)
        NSLayoutConstraint.activate([
            expandCollapseButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            expandCollapseButton.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -8),
            expandCollapseButton.widthAnchor.constraint(equalToConstant: 18.67),
            expandCollapseButton.heightAnchor.constraint(equalToConstant: 18.67),
        ])

        layer.cornerCurve = .continuous
        layer.cornerRadius = 16
        layer.masksToBounds = true

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(DSPValue1TableViewCell.self)
        tableView.register(DSPGraphTableViewCell.self)
        tableView.register(DSPIntervalTableViewCell.self)
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.alwaysBounceVertical = true
        tableView.isScrollEnabled = true
        tableView.contentInset.bottom = tableBottomPadding
        tableView.scrollIndicatorInsets.bottom = tableBottomPadding
        tableView.delegate = self
        tableView.dataSource = self

        resetPresentation()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(dashboardItems: [any DSPDashboardItem], configuration: DSPOptions.Widget?) {
        let wasVisible = !isHidden
        hide()
        self.dashboardItems = dashboardItems
        self.configuration = configuration
        tableView.reloadData()
        if wasVisible {
            show()
        } else {
            resetPresentation()
        }
    }

    func show() {
        guard !isMonitoring else {
            isHidden = false
            return
        }

        resetPresentation()
        isHidden = false
        reloadData()
        visibleDashboardItems.forEach({ $0.startMonitoring() })
        Timer.publish(every: 1, on: .main, in: .default).autoconnect()
            .sink { [weak self] _ in
                self?.reloadData()
            }
            .store(in: &cancellables)
        isMonitoring = true
    }

    func hide() {
        guard isMonitoring || !isHidden else {
            resetPresentation()
            return
        }

        visibleDashboardItems.forEach({ $0.stopMonitoring() })
        cancellables = []
        isMonitoring = false
        isHidden = true
        resetPresentation()
    }

    private func reloadData() {
        visibleDashboardItems.forEach({ $0.update() })
        tableView.reloadData()
    }

    private var visibleDashboardItems: [any DSPDashboardItem] {
        guard let configuration = configuration else {
            return dashboardItems
        }

        return dashboardItems.filter { item in
            let widgetItem = item.widgetItem
            return configuration.visibleItems.contains(where: { $0.matches(widgetItem) })
        }
    }

    private func resetPresentation() {
        isExpanded = false
        applyStyle()
        applyCollapsedFrame()
        ensureVisibleWithinScreen()
        updateExpandCollapseButtonImage()
        tableView.isScrollEnabled = true
        tableView.contentInset.bottom = tableBottomPadding
        tableView.scrollIndicatorInsets.bottom = tableBottomPadding
    }

    private func applyStyle() {
        contentView.backgroundColor = configuration?.backgroundColor ?? .clear
        layer.borderColor = configuration?.borderColor?.cgColor
        layer.borderWidth = configuration?.borderColor == nil ? 0 : (configuration?.borderWidth ?? 1)
        effect = defaultEffect
    }

    private func applyCollapsedFrame() {
        let collapsedFrame = configuration?.frame ?? DSPOptions.Widget.defaultFrame
        frame = CGRect(origin: frame.origin, size: collapsedFrame.size)
    }

    private func toggleExpandedState() {
        guard !isHidden else { return }

        let targetExpanded = !isExpanded
        isExpanded = targetExpanded
        applyCurrentSize(expanded: targetExpanded, animated: true)
        updateExpandCollapseButtonImage(for: targetExpanded)
    }

    func shouldBeginDragging(with touch: UITouch) -> Bool {
        let point = touch.location(in: self)
        guard headerView.frame.contains(point) else {
            return false
        }

        let pointInButton = touch.location(in: expandCollapseButton)
        if expandCollapseButton.bounds.contains(pointInButton) {
            return false
        }

        let pointInCloseButton = touch.location(in: closeButton)
        return !closeButton.bounds.contains(pointInCloseButton)
    }

    private func updateExpandCollapseButtonImage(for expanded: Bool? = nil) {
        let imageName = if expanded ?? isExpanded {
            "arrow.up.right.and.arrow.down.left"
        } else {
            "arrow.down.left.and.arrow.up.right"
        }
        expandCollapseButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    private func applyCurrentSize(expanded: Bool, animated: Bool) {
        let size = expanded ? expandedSize() : collapsedSize()
        tableView.isScrollEnabled = true
        let updates = {
            self.applyExpandedStateToVisibleCells(expanded: expanded, animated: animated)
            self.frame = self.targetFrame(for: size)
            self.layoutIfNeeded()
            self.tableView.layoutIfNeeded()
        }

        let completion: (Bool) -> Void = { _ in
            self.isExpanded = expanded
            self.reconcilePresentationState(expanded: expanded)
            self.ensureVisibleWithinScreen(animated: false)
        }

        if animated {
            UIView.animate(
                withDuration: 0.28,
                delay: 0,
                usingSpringWithDamping: 0.88,
                initialSpringVelocity: 0.2,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) {
                updates()
            } completion: { finished in
                completion(finished)
            }
        } else {
            updates()
            completion(true)
        }
    }

    private func targetFrame(for size: CGSize) -> CGRect {
        guard let containerView = superview else {
            return CGRect(origin: frame.origin, size: size)
        }

        let safeInsets = containerView.safeAreaInsets
        let minX = widgetMargin + safeInsets.left
        let maxX = containerView.bounds.width - widgetMargin - safeInsets.right - size.width
        let minY = widgetMargin + safeInsets.top
        let maxY = containerView.bounds.height - widgetMargin - safeInsets.bottom - size.height

        let currentFrame = currentVisualFrame
        let anchorsTrailing = currentFrame.midX > containerView.bounds.midX
        let anchorsBottom = currentFrame.midY > containerView.bounds.midY

        let originX = anchorsTrailing ? currentFrame.maxX - size.width : currentFrame.minX
        let originY = anchorsBottom ? currentFrame.maxY - size.height : currentFrame.minY
        
        return CGRect(
            x: min(max(originX, minX), max(minX, maxX)),
            y: min(max(originY, minY), max(minY, maxY)),
            width: size.width,
            height: size.height
        )
    }

    private func ensureVisibleWithinScreen(animated: Bool = false) {
        guard let containerView = superview else { return }

//        containerView.layoutIfNeeded()

        let safeInsets = containerView.safeAreaInsets
        let minX = widgetMargin + safeInsets.left
        let maxX = containerView.bounds.width - widgetMargin - safeInsets.right - frame.width
        let minY = widgetMargin + safeInsets.top
        let maxY = containerView.bounds.height - widgetMargin - safeInsets.bottom - frame.height

        let clampedFrame = CGRect(
            x: min(max(frame.origin.x, minX), max(minX, maxX)),
            y: min(max(frame.origin.y, minY), max(minY, maxY)),
            width: frame.width,
            height: frame.height
        )

        guard clampedFrame != frame else { return }

        let updates = {
            self.frame = clampedFrame
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.18, animations: updates)
        } else {
            updates()
        }
    }

    private func reconcilePresentationState(expanded: Bool) {
        let desiredSize = expanded ? expandedSize() : collapsedSize()
        let desiredFrame = targetFrame(for: desiredSize)
        guard desiredFrame != frame else { return }
        frame = desiredFrame
        layoutIfNeeded()
        tableView.layoutIfNeeded()
    }

    private func applyExpandedStateToVisibleCells(expanded: Bool, animated: Bool) {
        tableView.visibleCells.forEach { cell in
            switch cell {
            case let graphCell as DSPGraphTableViewCell:
                graphCell.setExpanded(expanded, animated: animated)
            case let intervalCell as DSPIntervalTableViewCell:
                intervalCell.setExpanded(expanded, animated: animated)
            default:
                break
            }
        }
    }

    private func collapsedSize() -> CGSize {
        (configuration?.frame ?? DSPOptions.Widget.defaultFrame).size
    }

    private func expandedSize() -> CGSize {
        let containerBounds = superview?.bounds ?? UIScreen.main.bounds
        let safeInsets = superview?.safeAreaInsets ?? .zero
        let width = containerBounds.width - safeInsets.left - safeInsets.right - (widgetMargin * 2)

        tableView.layoutIfNeeded()
        let contentHeight = tableView.contentSize.height + headerHeight
        let maxHeight = ((containerBounds.height - safeInsets.top - safeInsets.bottom) / 2) + 100
        let height = min(max(contentHeight, collapsedSize().height), maxHeight)
        return CGSize(width: width, height: height)
    }

    private var currentVisualFrame: CGRect {
        layer.presentation()?.frame ?? frame
    }
}

extension DSPWidgetView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleDashboardItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = visibleDashboardItems[indexPath.row]
        switch item.fetcher {
        case let .text(fetcher):
            let cell = tableView.dequeue(DSPValue1TableViewCell.self, for: indexPath)
            cell.selectionStyle = .none
            cell.textLabel?.text = item.title
            cell.textLabel?.textColor = .white
            cell.detailTextLabel?.text = fetcher()
            cell.detailTextLabel?.textColor = .lightGray
            cell.detailTextLabel?.numberOfLines = 0
            return cell
        case let .graph(fetcher):
            let cell = tableView.dequeue(DSPGraphTableViewCell.self, for: indexPath)
            cell.textLabel?.text = item.title
            cell.setExpanded(isExpanded, animated: false)
            cell.setData(fetcher())
            return cell
        case let .interval(fetcher):
            let cell = tableView.dequeue(DSPIntervalTableViewCell.self, for: indexPath)
            cell.textLabel?.text = item.title
            cell.setExpanded(isExpanded, animated: false)
            cell.setDurations(fetcher())
            return cell
        }
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cell.contentView.backgroundColor = .clear
        cell.backgroundColor = .clear
    }
}
