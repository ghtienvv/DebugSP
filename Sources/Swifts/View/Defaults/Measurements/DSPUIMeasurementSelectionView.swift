import UIKit

@MainActor
final class DSPUIMeasurementSelectionView: UIView, DSPUIMeasurementOverlay, UIGestureRecognizerDelegate {
    var attachedWindow: UIWindow? {
        didSet {
            clearSelection()
        }
    }

    private let primaryColor = UIColor.systemBlue
    private let secondaryColor = UIColor.systemGray2
    private let toolbarView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    private let titleLabel = UILabel(frame: .zero)
    private let detailLabel = UILabel(frame: .zero)
    private let clearButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    private var selectedView: UIView?
    private var comparedView: UIView?
    private var shapeLayers: [CAShapeLayer] = []
    private var labelViews: [DSPUIMeasurementLabelView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        renderSelection()
    }

    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)

        toolbarView.layer.cornerRadius = 16
        toolbarView.layer.cornerCurve = .continuous
        toolbarView.layer.masksToBounds = true
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toolbarView)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .white
        titleLabel.text = DSPUIMeasurement.Mode.selection.title

        detailLabel.font = .preferredFont(forTextStyle: .caption1)
        detailLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        detailLabel.numberOfLines = 2
        detailLabel.text = DSPUIMeasurement.Mode.selection.detailText

        clearButton.setTitle("Clear", for: .normal)
        clearButton.tintColor = .white
        clearButton.addAction(
            UIAction(handler: { [weak self] _ in
                self?.clearSelection()
            }),
            for: .touchUpInside
        )

        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addAction(
            UIAction(handler: { _ in
                DSPUIMeasurement.deactivate()
            }),
            for: .touchUpInside
        )

        let labelStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 2

        let buttonStack = UIStackView(arrangedSubviews: [clearButton, closeButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.alignment = .center

        let contentStack = UIStackView(arrangedSubviews: [labelStack, buttonStack])
        contentStack.axis = .horizontal
        contentStack.alignment = .top
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            toolbarView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            toolbarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            toolbarView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),

            contentStack.topAnchor.constraint(equalTo: toolbarView.contentView.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: toolbarView.contentView.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: toolbarView.contentView.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: toolbarView.contentView.bottomAnchor, constant: -12),
            toolbarView.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
        ])
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }
        return !touchedView.isDescendant(of: toolbarView)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let attachedWindow else {
            clearSelection()
            return
        }

        let point = gesture.location(in: self)
        let pointInWindow = convert(point, to: attachedWindow)
        let candidates = findSelectableViews(in: attachedWindow, intersectingPoint: pointInWindow)
        updateSelection(with: candidates.first)
    }

    private func updateSelection(with view: UIView?) {
        if view === comparedView {
            comparedView = nil
        } else if selectedView == nil {
            selectedView = view
        } else if view === selectedView {
            clearSelection()
            return
        } else {
            comparedView = view
        }

        renderSelection()
    }

    private func clearSelection() {
        selectedView = nil
        comparedView = nil
        clearDecorations()
    }

    private func renderSelection() {
        clearDecorations()

        guard let selectedView, let selectedRect = rect(for: selectedView) else { return }

        addBorder(for: selectedRect, color: primaryColor, dashed: false, lineWidth: 1.6)
        addGuides(for: selectedRect)

        let baselineView = comparedView ?? selectedView.superview
        if let comparedView, let comparedRect = rect(for: comparedView) {
            addBorder(for: comparedRect, color: secondaryColor, dashed: true, lineWidth: 1)
        }

        guard let baselineView, let baselineRect = rect(for: baselineView) else { return }
        addMeasurements(from: selectedRect, to: baselineRect)
    }

    private func clearDecorations() {
        shapeLayers.forEach { $0.removeFromSuperlayer() }
        shapeLayers.removeAll()
        labelViews.forEach { $0.removeFromSuperview() }
        labelViews.removeAll()
    }

    private func rect(for view: UIView) -> CGRect? {
        guard let superview = view.superview else { return nil }
        let convertedRect = superview.convert(view.frame, to: self)
        guard convertedRect.width > 0, convertedRect.height > 0 else { return nil }
        return convertedRect
    }

    private func addBorder(for rect: CGRect, color: UIColor, dashed: Bool, lineWidth: CGFloat) {
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(rect: rect).cgPath
        layer.strokeColor = color.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = lineWidth
        layer.lineDashPattern = dashed ? [4, 4] : nil
        self.layer.addSublayer(layer)
        shapeLayers.append(layer)
    }

    private func addGuides(for rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX, y: bounds.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: bounds.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: bounds.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: bounds.maxY))
        path.move(to: CGPoint(x: bounds.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: rect.minY))
        path.move(to: CGPoint(x: bounds.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: rect.maxY))

        let guideLayer = CAShapeLayer()
        guideLayer.path = path.cgPath
        guideLayer.strokeColor = primaryColor.withAlphaComponent(0.75).cgColor
        guideLayer.fillColor = UIColor.clear.cgColor
        guideLayer.lineWidth = 1
        guideLayer.lineDashPattern = [3, 6]
        layer.addSublayer(guideLayer)
        shapeLayers.append(guideLayer)
    }

    private func addMeasurements(from selectedRect: CGRect, to compareRect: CGRect) {
        addVerticalMeasurement(
            from: CGPoint(x: selectedRect.midX, y: selectedRect.minY),
            to: verticalTarget(from: selectedRect, compareRect: compareRect, top: true)
        )
        addVerticalMeasurement(
            from: CGPoint(x: selectedRect.midX, y: selectedRect.maxY),
            to: verticalTarget(from: selectedRect, compareRect: compareRect, top: false)
        )
        addHorizontalMeasurement(
            from: CGPoint(x: selectedRect.minX, y: selectedRect.midY),
            to: horizontalTarget(from: selectedRect, compareRect: compareRect, leading: true)
        )
        addHorizontalMeasurement(
            from: CGPoint(x: selectedRect.maxX, y: selectedRect.midY),
            to: horizontalTarget(from: selectedRect, compareRect: compareRect, leading: false)
        )
    }

    private func verticalTarget(from selectedRect: CGRect, compareRect: CGRect, top: Bool) -> CGPoint {
        let x = selectedRect.midX
        if top {
            if compareRect.contains(CGPoint(x: x, y: selectedRect.minY)) {
                return CGPoint(x: x, y: compareRect.minY)
            }
            return CGPoint(x: x, y: selectedRect.minY >= compareRect.maxY ? compareRect.maxY : compareRect.minY)
        }

        if compareRect.contains(CGPoint(x: x, y: selectedRect.maxY)) {
            return CGPoint(x: x, y: compareRect.maxY)
        }
        return CGPoint(x: x, y: selectedRect.maxY <= compareRect.minY ? compareRect.minY : compareRect.maxY)
    }

    private func horizontalTarget(from selectedRect: CGRect, compareRect: CGRect, leading: Bool) -> CGPoint {
        let y = selectedRect.midY
        if leading {
            if compareRect.contains(CGPoint(x: selectedRect.minX, y: y)) {
                return CGPoint(x: compareRect.minX, y: y)
            }
            return CGPoint(x: selectedRect.minX >= compareRect.maxX ? compareRect.maxX : compareRect.minX, y: y)
        }

        if compareRect.contains(CGPoint(x: selectedRect.maxX, y: y)) {
            return CGPoint(x: compareRect.maxX, y: y)
        }
        return CGPoint(x: selectedRect.maxX <= compareRect.minX ? compareRect.minX : compareRect.maxX, y: y)
    }

    private func addVerticalMeasurement(from start: CGPoint, to end: CGPoint) {
        guard start.y != end.y else { return }
        let lineLayer = measurementLayer(from: start, to: end)
        layer.addSublayer(lineLayer)
        shapeLayers.append(lineLayer)

        let value = DSPUIMeasurementLabelView()
        value.text = String(format: "%.1fpt", abs(start.y - end.y))
        value.center = CGPoint(x: start.x + 18, y: start.y + ((end.y - start.y) / 2))
        value.clamp(to: bounds.insetBy(dx: 12, dy: 12))
        addSubview(value)
        labelViews.append(value)
    }

    private func addHorizontalMeasurement(from start: CGPoint, to end: CGPoint) {
        guard start.x != end.x else { return }
        let lineLayer = measurementLayer(from: start, to: end)
        layer.addSublayer(lineLayer)
        shapeLayers.append(lineLayer)

        let value = DSPUIMeasurementLabelView()
        value.text = String(format: "%.1fpt", abs(start.x - end.x))
        value.center = CGPoint(x: start.x + ((end.x - start.x) / 2), y: start.y - 18)
        value.clamp(to: bounds.insetBy(dx: 12, dy: 12))
        addSubview(value)
        labelViews.append(value)
    }

    private func measurementLayer(from start: CGPoint, to end: CGPoint) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.path = measurementPath(from: start, to: end).cgPath
        layer.strokeColor = primaryColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 1
        return layer
    }

    private func measurementPath(from start: CGPoint, to end: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        let isVertical = abs(start.x - end.x) < 0.5
        if isVertical {
            let adjustedStartY = start.y + (start.y < end.y ? 4 : -4)
            let adjustedEndY = end.y + (start.y < end.y ? -4 : 4)
            path.move(to: CGPoint(x: start.x - 5, y: adjustedStartY))
            path.addLine(to: CGPoint(x: start.x + 5, y: adjustedStartY))
            path.move(to: CGPoint(x: start.x, y: adjustedStartY))
            path.addLine(to: CGPoint(x: end.x, y: adjustedEndY))
            path.move(to: CGPoint(x: end.x - 5, y: adjustedEndY))
            path.addLine(to: CGPoint(x: end.x + 5, y: adjustedEndY))
        } else {
            let adjustedStartX = start.x + (start.x < end.x ? 4 : -4)
            let adjustedEndX = end.x + (start.x < end.x ? -4 : 4)
            path.move(to: CGPoint(x: adjustedStartX, y: start.y - 5))
            path.addLine(to: CGPoint(x: adjustedStartX, y: start.y + 5))
            path.move(to: CGPoint(x: adjustedStartX, y: start.y))
            path.addLine(to: CGPoint(x: adjustedEndX, y: end.y))
            path.move(to: CGPoint(x: adjustedEndX, y: end.y - 5))
            path.addLine(to: CGPoint(x: adjustedEndX, y: end.y + 5))
        }
        return path
    }

    private func findSelectableViews(in view: UIView, intersectingPoint point: CGPoint) -> [UIView] {
        var candidates: [UIView] = []

        for subview in view.subviews.reversed() {
            guard subview.alpha > 0, !subview.isHidden, subview.bounds.width > 0, subview.bounds.height > 0 else {
                continue
            }

            let pointInSubview = view.convert(point, to: subview)
            candidates.append(contentsOf: findSelectableViews(in: subview, intersectingPoint: pointInSubview))

            if subview.bounds.contains(pointInSubview) || subview.point(inside: pointInSubview, with: nil) {
                if !shouldIgnoreForSelection(subview) {
                    candidates.append(subview)
                }
            }
        }

        return candidates
    }

    private func shouldIgnoreForSelection(_ view: UIView) -> Bool {
        let className = NSStringFromClass(type(of: view))
        if className.hasPrefix("DebugSP.") {
            return true
        }

        return ["_UINavigationControllerPaletteClippingView"].contains(className)
    }
}
