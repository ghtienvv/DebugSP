import UIKit

@MainActor
final class DSPUIMeasurementManualView: UIView, DSPUIMeasurementOverlay, UIGestureRecognizerDelegate {
    private enum MeasurementLineMode: Int {
        case horizontal
        case vertical
        case both
    }

    private enum ToolbarPage {
        case controls
        case movement
    }

    private enum MovementDirection: Int {
        case up
        case down
        case left
        case right
    }

    private struct AccentOption {
        let title: String
        let color: UIColor
    }

    var attachedWindow: UIWindow? {
        didSet { setNeedsLayout() }
    }

    private let accentOptions: [AccentOption] = [
        .init(title: "Blue", color: .systemBlue),
        .init(title: "White", color: .white),
        .init(title: "Black", color: .black),
        .init(title: "Red", color: .systemRed),
        .init(title: "Yellow", color: .systemYellow),
    ]

    private let gridOverlayView = DSPUIGridOverlayView(frame: .zero)
    private let toolbarView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    private let toolbarBackgroundView = UIView(frame: .zero)
    private let controlsPageView = UIView(frame: .zero)
    private let movementPageView = UIView(frame: .zero)
    private let compactOpenButton = UIButton(type: .system)
    private let headerContainerView = UIView(frame: .zero)
    private let toolbarPanGesture = UIPanGestureRecognizer()

    private let titleLabel = UILabel(frame: .zero)
    private let detailLabel = UILabel(frame: .zero)
    private let measurementSectionTitleLabel = UILabel(frame: .zero)
    private let gridSectionTitleLabel = UILabel(frame: .zero)
    private let movementTitleLabel = UILabel(frame: .zero)
    private let movementHintLabel = UILabel(frame: .zero)
    private let movementCenterView = UIView(frame: .zero)
    private let movementCenterLabel = UIButton(type: .system)
    private let verticalMeasurementDragBand = UIView(frame: .zero)
    private let horizontalMeasurementDragBand = UIView(frame: .zero)

    private let axisControl = UISegmentedControl(items: ["H", "V", "Both"])
    private let movementAxisControl = UISegmentedControl(items: ["H", "V", "Both"])
    private let collapseButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    private let movementModeButton = UIButton(type: .system)
    private let movementBackButton = UIButton(type: .system)
    private let moveUpButton = UIButton(type: .system)
    private let moveDownButton = UIButton(type: .system)
    private let moveLeftButton = UIButton(type: .system)
    private let moveRightButton = UIButton(type: .system)
    private let movementStepButton = UIButton(type: .system)

    private let lineColorButton = UIButton(type: .system)
    private let movementLineColorButton = UIButton(type: .system)
    private let lineOpacityButton = UIButton(type: .system)
    private let movementLineOpacityButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let movementResetButton = UIButton(type: .system)

    private let gridToggleSwitch = UISwitch(frame: .zero)
    private let movementGridToggleSwitch = UISwitch(frame: .zero)
    private let gridDecreaseButton = UIButton(type: .system)
    private let gridIncreaseButton = UIButton(type: .system)
    private let gridSizeLabel = UIButton(type: .system)
    private let gridColorButton = UIButton(type: .system)
    private let movementGridColorButton = UIButton(type: .system)
    private let gridOpacityButton = UIButton(type: .system)
    private let movementGridOpacityButton = UIButton(type: .system)

    private let verticalGuide = DSPUIMeasurementGuideHandle(axis: .vertical)
    private let horizontalGuide = DSPUIMeasurementGuideHandle(axis: .horizontal)
    private let marginLayer = CAShapeLayer()
    private let leftLabel = DSPUIMeasurementLabelView()
    private let rightLabel = DSPUIMeasurementLabelView()
    private let topLabel = DSPUIMeasurementLabelView()
    private let bottomLabel = DSPUIMeasurementLabelView()

    private var controlsPageStack: UIStackView?
    private weak var gridSectionContainerView: UIView?
    private weak var movementInlineContainerView: UIView?
    private var lineMode: MeasurementLineMode = .both
    private var toolbarPage: ToolbarPage = .controls
    private var isMovementControlsVisible = false
    private var isToolbarVisible = true
    private var isGridVisible = false
    private var lineColor: UIColor = .systemBlue
    private var gridColor: UIColor = .systemBlue
    private var measurementOpacity: CGFloat = 1
    private var gridOpacity: CGFloat = 1
    private var movementStep: CGFloat = 1
    private var toolbarLeadingConstraint: NSLayoutConstraint?
    private var toolbarTopConstraint: NSLayoutConstraint?
    private var toolbarWidthConstraint: NSLayoutConstraint?
    private var toolbarHeightConstraint: NSLayoutConstraint?
    private var verticalGuideX: CGFloat?
    private var horizontalGuideY: CGFloat?
    private var movementBootstrapTimer: Timer?
    private var movementRepeatTimer: Timer?
    private var repeatDirection: MovementDirection?
    private var defaultExpandedToolbarHeight: CGFloat?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        resetGuidePositionsIfNeeded()
        layoutGuides()
        updateGuideVisibility()
        updateMargins()
        applyToolbarVisibility(animated: false)
        ensureToolbarVisibleWithinScreen(animated: false)
        bringSubviewToFront(toolbarView)
    }

    private func setup() {
        backgroundColor = .clear

        gridOverlayView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gridOverlayView)
        NSLayoutConstraint.activate([
            gridOverlayView.topAnchor.constraint(equalTo: topAnchor),
            gridOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gridOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gridOverlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        gridOverlayView.isHidden = true

        marginLayer.fillColor = UIColor.clear.cgColor
        marginLayer.lineWidth = 1
        marginLayer.lineDashPattern = [4, 4]
        layer.addSublayer(marginLayer)

        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.layer.cornerCurve = .continuous
        toolbarView.layer.cornerRadius = 16
        toolbarView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMinXMaxYCorner]
        toolbarView.layer.masksToBounds = true
        addSubview(toolbarView)
        toolbarPanGesture.addTarget(self, action: #selector(handleToolbarPan(_:)))
        toolbarPanGesture.delegate = self
        toolbarPanGesture.cancelsTouchesInView = false
        toolbarView.addGestureRecognizer(toolbarPanGesture)

        toolbarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.contentView.addSubview(toolbarBackgroundView)
        NSLayoutConstraint.activate([
            toolbarBackgroundView.topAnchor.constraint(equalTo: toolbarView.contentView.topAnchor),
            toolbarBackgroundView.leadingAnchor.constraint(equalTo: toolbarView.contentView.leadingAnchor),
            toolbarBackgroundView.trailingAnchor.constraint(equalTo: toolbarView.contentView.trailingAnchor),
            toolbarBackgroundView.bottomAnchor.constraint(equalTo: toolbarView.contentView.bottomAnchor),
        ])

        controlsPageView.translatesAutoresizingMaskIntoConstraints = false
        movementPageView.translatesAutoresizingMaskIntoConstraints = false
        compactOpenButton.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.contentView.addSubview(controlsPageView)
        toolbarView.contentView.addSubview(movementPageView)
        toolbarView.contentView.addSubview(compactOpenButton)

        [controlsPageView, movementPageView].forEach { pageView in
            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: toolbarView.contentView.topAnchor),
                pageView.leadingAnchor.constraint(equalTo: toolbarView.contentView.leadingAnchor),
                pageView.trailingAnchor.constraint(equalTo: toolbarView.contentView.trailingAnchor),
                pageView.bottomAnchor.constraint(equalTo: toolbarView.contentView.bottomAnchor),
            ])
        }

        NSLayoutConstraint.activate([
            compactOpenButton.centerXAnchor.constraint(equalTo: toolbarView.contentView.centerXAnchor),
            compactOpenButton.centerYAnchor.constraint(equalTo: toolbarView.contentView.centerYAnchor),
            compactOpenButton.widthAnchor.constraint(equalToConstant: 28),
            compactOpenButton.heightAnchor.constraint(equalToConstant: 28),
        ])

        setupLabels()
        setupButtons()
        setupControlPages()
        setupGuides()

        toolbarLeadingConstraint = toolbarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12)
        toolbarTopConstraint = toolbarView.topAnchor.constraint(equalTo: topAnchor, constant: 12)
        toolbarWidthConstraint = toolbarView.widthAnchor.constraint(equalToConstant: 340)
        toolbarHeightConstraint = toolbarView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            toolbarTopConstraint!,
            toolbarLeadingConstraint!,
            toolbarWidthConstraint!,
            toolbarHeightConstraint!,
        ])

        rebuildMenus()
        updateGridState()
        updateMeasurementAppearance()
        updateToolbarPage()
        updateToolbarVisibilityState()
        updateInlineMovementState()
    }

    private func setupLabels() {
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .white
        titleLabel.text = DSPUIMeasurement.Mode.manual.title

        detailLabel.font = .preferredFont(forTextStyle: .caption1)
        detailLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        detailLabel.numberOfLines = 2
        detailLabel.text = DSPUIMeasurement.Mode.manual.detailText

        [measurementSectionTitleLabel, gridSectionTitleLabel, movementTitleLabel].forEach {
            $0.font = .preferredFont(forTextStyle: .subheadline)
            $0.textColor = .white
        }
        measurementSectionTitleLabel.text = "Measurement Line"
        gridSectionTitleLabel.text = "Grid"
        movementTitleLabel.text = "Movement"

        movementHintLabel.font = .preferredFont(forTextStyle: .caption1)
        movementHintLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        movementHintLabel.numberOfLines = 1
        movementHintLabel.text = "Tap once or hold to keep moving."

        movementCenterView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        movementCenterView.layer.cornerRadius = 15
        movementCenterView.layer.cornerCurve = .continuous
        movementCenterView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            movementCenterView.widthAnchor.constraint(equalToConstant: 30),
            movementCenterView.heightAnchor.constraint(equalToConstant: 30),
        ])

        movementCenterLabel.setTitleColor(.white, for: .normal)
        movementCenterLabel.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        movementCenterLabel.backgroundColor = .clear
        movementCenterLabel.showsMenuAsPrimaryAction = true
        movementCenterLabel.translatesAutoresizingMaskIntoConstraints = false
        movementCenterView.addSubview(movementCenterLabel)
        NSLayoutConstraint.activate([
            movementCenterLabel.topAnchor.constraint(equalTo: movementCenterView.topAnchor),
            movementCenterLabel.leadingAnchor.constraint(equalTo: movementCenterView.leadingAnchor),
            movementCenterLabel.trailingAnchor.constraint(equalTo: movementCenterView.trailingAnchor),
            movementCenterLabel.bottomAnchor.constraint(equalTo: movementCenterView.bottomAnchor),
        ])

        [axisControl, movementAxisControl].forEach(configureAxisControl)

        gridSizeLabel.setTitleColor(.white, for: .normal)
        gridSizeLabel.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        gridSizeLabel.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        gridSizeLabel.layer.cornerRadius = 8
        gridSizeLabel.layer.cornerCurve = .continuous
        gridSizeLabel.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        gridSizeLabel.showsMenuAsPrimaryAction = true
        gridSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        gridSizeLabel.widthAnchor.constraint(equalToConstant: 62).isActive = true
        gridSizeLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }

    private func setupButtons() {
        configureActionButton(collapseButton, imageName: "chevron.left.circle.fill") {
            [weak self] in self?.toggleToolbarVisibility()
        }
        configureActionButton(closeButton, imageName: "xmark.circle.fill") {
            DSPUIMeasurement.deactivate()
        }
        configureActionButton(compactOpenButton, imageName: "chevron.right") {
            [weak self] in self?.showToolbarAfterCollapse()
        }
        configureActionButton(movementModeButton, imageName: "arrow.up.and.down.and.arrow.left.and.right") {
            [weak self] in self?.toggleInlineMovementControls(animated: true)
        }
        configureActionButton(movementBackButton, imageName: "chevron.left") {
            [weak self] in self?.setToolbarPage(.movement, animated: true)
        }
        movementBackButton.removeTarget(nil, action: nil, for: .allEvents)
        movementBackButton.addAction(UIAction(handler: { [weak self] _ in
            self?.setToolbarPage(.controls, animated: true)
        }), for: .touchUpInside)

        configureMovementButton(moveUpButton, imageName: "arrow.up", direction: .up)
        configureMovementButton(moveDownButton, imageName: "arrow.down", direction: .down)
        configureMovementButton(moveLeftButton, imageName: "arrow.left", direction: .left)
        configureMovementButton(moveRightButton, imageName: "arrow.right", direction: .right)

        configureColorSwatchButton(lineColorButton)
        configureColorSwatchButton(movementLineColorButton)
        lineColorButton.showsMenuAsPrimaryAction = true
        movementLineColorButton.showsMenuAsPrimaryAction = true
        configurePillButton(lineOpacityButton, title: "Opacity 1.0")
        configurePillButton(movementLineOpacityButton, title: "Opacity 1.0")
        lineOpacityButton.showsMenuAsPrimaryAction = true
        movementLineOpacityButton.showsMenuAsPrimaryAction = true
        configurePillButton(resetButton, title: "Reset")
        configurePillButton(movementResetButton, title: "Reset")
        resetButton.addAction(UIAction(handler: { [weak self] _ in
            self?.resetGuidesToCenter(animated: true)
        }), for: .touchUpInside)
        movementResetButton.addAction(UIAction(handler: { [weak self] _ in
            self?.resetGuidesToCenter(animated: true)
        }), for: .touchUpInside)

        [gridToggleSwitch, movementGridToggleSwitch].forEach(configureGridToggleSwitch)
        configureStepperButton(gridDecreaseButton, title: "-")
        gridDecreaseButton.addAction(UIAction(handler: { [weak self] _ in
            self?.adjustGridSize(by: -1)
        }), for: .touchUpInside)
        configureStepperButton(gridIncreaseButton, title: "+")
        gridIncreaseButton.addAction(UIAction(handler: { [weak self] _ in
            self?.adjustGridSize(by: 1)
        }), for: .touchUpInside)
        configureColorSwatchButton(gridColorButton)
        configureColorSwatchButton(movementGridColorButton)
        gridColorButton.showsMenuAsPrimaryAction = true
        movementGridColorButton.showsMenuAsPrimaryAction = true
        configurePillButton(gridOpacityButton, title: "Opacity 1.0")
        configurePillButton(movementGridOpacityButton, title: "Opacity 1.0")
        gridOpacityButton.showsMenuAsPrimaryAction = true
        movementGridOpacityButton.showsMenuAsPrimaryAction = true
        configurePillButton(movementStepButton, title: "Step 1.0pt")
        movementStepButton.showsMenuAsPrimaryAction = true
    }

    private func setupControlPages() {
        let headerTextStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        headerTextStack.axis = .vertical
        headerTextStack.spacing = 2

        let headerButtonStack = UIStackView(arrangedSubviews: [collapseButton, closeButton])
        headerButtonStack.axis = .horizontal
        headerButtonStack.spacing = 8

        let headerRow = UIStackView(arrangedSubviews: [headerTextStack, headerButtonStack])
        headerRow.axis = .horizontal
        headerRow.alignment = .top
        headerRow.spacing = 12
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        headerContainerView.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.addSubview(headerRow)
        NSLayoutConstraint.activate([
            headerRow.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            headerRow.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            headerRow.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
        ])

        let measurementHeaderRow = UIStackView(arrangedSubviews: [measurementSectionTitleLabel, UIView(), axisControl, lineColorButton])
        measurementHeaderRow.axis = .horizontal
        measurementHeaderRow.alignment = .center
        measurementHeaderRow.spacing = 8

        let measurementPrimaryRow = UIStackView(arrangedSubviews: [lineOpacityButton, resetButton, movementModeButton])
        measurementPrimaryRow.axis = .horizontal
        measurementPrimaryRow.alignment = .center
        measurementPrimaryRow.spacing = 8
        lineOpacityButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let measurementSectionStack = UIStackView(arrangedSubviews: [measurementHeaderRow, measurementPrimaryRow])
        measurementSectionStack.axis = .vertical
        measurementSectionStack.spacing = 8

        let measurementSection = sectionView(content: measurementSectionStack)

        let gridHeaderRow = UIStackView(arrangedSubviews: [gridSectionTitleLabel, UIView(), gridToggleSwitch, gridColorButton])
        gridHeaderRow.axis = .horizontal
        gridHeaderRow.alignment = .center
        gridHeaderRow.spacing = 8

        let gridPrimaryControls = UIStackView(arrangedSubviews: [gridDecreaseButton, gridSizeLabel, gridIncreaseButton, gridOpacityButton])
        gridPrimaryControls.axis = .horizontal
        gridPrimaryControls.spacing = 8
        gridPrimaryControls.alignment = .center

        let gridSectionStack = UIStackView(arrangedSubviews: [gridHeaderRow, gridPrimaryControls])
        gridSectionStack.axis = .vertical
        gridSectionStack.spacing = 8

        let gridSection = sectionView(content: gridSectionStack)
        gridSectionContainerView = gridSection

        let movementStepRow = UIStackView(arrangedSubviews: [movementCenterView, UIView()])
        movementStepRow.axis = .horizontal
        movementStepRow.alignment = .center

        let movementCrossView = UIView(frame: .zero)
        movementCrossView.translatesAutoresizingMaskIntoConstraints = false
        movementCrossView.addSubview(moveUpButton)
        movementCrossView.addSubview(moveLeftButton)
        movementCrossView.addSubview(moveRightButton)
        movementCrossView.addSubview(moveDownButton)
        NSLayoutConstraint.activate([
            movementCrossView.heightAnchor.constraint(equalToConstant: 88),

            moveUpButton.centerXAnchor.constraint(equalTo: movementCrossView.centerXAnchor),
            moveUpButton.topAnchor.constraint(equalTo: movementCrossView.topAnchor),

            moveLeftButton.trailingAnchor.constraint(equalTo: movementCrossView.centerXAnchor, constant: -20),
            moveLeftButton.centerYAnchor.constraint(equalTo: movementCrossView.centerYAnchor),

            moveRightButton.leadingAnchor.constraint(equalTo: movementCrossView.centerXAnchor, constant: 20),
            moveRightButton.centerYAnchor.constraint(equalTo: movementCrossView.centerYAnchor),

            moveDownButton.centerXAnchor.constraint(equalTo: movementCrossView.centerXAnchor),
            moveDownButton.bottomAnchor.constraint(equalTo: movementCrossView.bottomAnchor),
        ])
        
        let movementInlineStack = UIStackView(arrangedSubviews: [movementStepRow, movementCrossView])
        movementInlineStack.axis = .horizontal
        movementInlineStack.alignment = .top

        let movementInlineSection = sectionView(content: movementInlineStack)
        movementInlineSection.isHidden = true
        movementInlineContainerView = movementInlineSection

        let mainStack = UIStackView(arrangedSubviews: [headerContainerView, measurementSection, gridSection, movementInlineSection])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        controlsPageView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: controlsPageView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: controlsPageView.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: controlsPageView.trailingAnchor, constant: -12),
            mainStack.bottomAnchor.constraint(equalTo: controlsPageView.bottomAnchor, constant: -12),
        ])
        controlsPageStack = mainStack

        movementPageView.isHidden = true
    }

    private func setupGuides() {
        verticalMeasurementDragBand.backgroundColor = .clear
        horizontalMeasurementDragBand.backgroundColor = .clear
        addSubview(verticalMeasurementDragBand)
        addSubview(horizontalMeasurementDragBand)
        addSubview(verticalGuide)
        addSubview(horizontalGuide)
        [leftLabel, rightLabel, topLabel, bottomLabel].forEach(addSubview)

        let verticalMeasurementPan = UIPanGestureRecognizer(target: self, action: #selector(handleVerticalPan(_:)))
        verticalMeasurementPan.cancelsTouchesInView = false
        verticalMeasurementDragBand.addGestureRecognizer(verticalMeasurementPan)

        let horizontalMeasurementPan = UIPanGestureRecognizer(target: self, action: #selector(handleHorizontalPan(_:)))
        horizontalMeasurementPan.cancelsTouchesInView = false
        horizontalMeasurementDragBand.addGestureRecognizer(horizontalMeasurementPan)

        let verticalPan = UIPanGestureRecognizer(target: self, action: #selector(handleVerticalPan(_:)))
        verticalPan.cancelsTouchesInView = false
        verticalGuide.addGestureRecognizer(verticalPan)

        let horizontalPan = UIPanGestureRecognizer(target: self, action: #selector(handleHorizontalPan(_:)))
        horizontalPan.cancelsTouchesInView = false
        horizontalGuide.addGestureRecognizer(horizontalPan)

        bringSubviewToFront(toolbarView)
    }

    private func sectionView(content: UIView) -> UIView {
        let stack = UIStackView(arrangedSubviews: [content])
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }

    private func configureActionButton(_ button: UIButton, imageName: String, action: @escaping () -> Void) {
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold), forImageIn: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.layer.cornerRadius = 10
        button.layer.cornerCurve = .continuous
        button.addAction(UIAction(handler: { _ in action() }), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    private func configureMovementButton(_ button: UIButton, imageName: String, direction: MovementDirection) {
        button.tag = direction.rawValue
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .bold), forImageIn: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.layer.cornerRadius = 10
        button.layer.cornerCurve = .continuous
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30),
        ])
        button.addTarget(self, action: #selector(handleMovementButtonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(handleMovementButtonTouchUp(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(handleMovementButtonTouchUp(_:)), for: .touchUpOutside)
        button.addTarget(self, action: #selector(handleMovementButtonTouchUp(_:)), for: .touchCancel)
        button.addTarget(self, action: #selector(handleMovementButtonTouchUp(_:)), for: .touchDragExit)
    }

    private func configurePillButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
    }

    private func configureStepperButton(_ button: UIButton, title: String) {
        configurePillButton(button, title: title)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 30),
        ])
    }

    private func configureGridToggleSwitch(_ toggleSwitch: UISwitch) {
        toggleSwitch.onTintColor = gridColor
        toggleSwitch.addAction(UIAction(handler: { [weak self, weak toggleSwitch] _ in
            guard let self, let toggleSwitch else { return }
            self.isGridVisible = toggleSwitch.isOn
            self.updateGridState()
        }), for: .valueChanged)
    }

    private func configureAxisControl(_ control: UISegmentedControl) {
        control.selectedSegmentIndex = MeasurementLineMode.both.rawValue
        control.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.22)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.widthAnchor.constraint(equalToConstant: 160).isActive = true
        control.addAction(UIAction(handler: { [weak self, weak control] _ in
            guard let self, let control else { return }
            let mode = MeasurementLineMode(rawValue: control.selectedSegmentIndex) ?? .both
            self.setGuideMode(mode, source: control)
        }), for: .valueChanged)
    }

    private func configureColorSwatchButton(_ button: UIButton) {
        button.setTitle(nil, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.layer.cornerRadius = 14
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 28),
            button.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    private func resetGuidePositionsIfNeeded() {
        if verticalGuideX == nil { verticalGuideX = bounds.midX }
        if horizontalGuideY == nil { horizontalGuideY = bounds.midY }
    }

    private func layoutGuides() {
        let x = clamp(verticalGuideX ?? bounds.midX, min: bounds.minX, max: bounds.maxX)
        let y = clamp(horizontalGuideY ?? bounds.midY, min: bounds.minY, max: bounds.maxY)
        verticalGuideX = x
        horizontalGuideY = y

        verticalMeasurementDragBand.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 56)
        horizontalMeasurementDragBand.frame = CGRect(x: 0, y: 0, width: 56, height: bounds.height)
        verticalGuide.frame = CGRect(x: x - 28, y: bounds.minY - 28, width: 56, height: bounds.height + 56)
        horizontalGuide.frame = CGRect(x: bounds.minX - 28, y: y - 28, width: bounds.width + 56, height: 56)
    }

    private func updateGuideVisibility() {
        let showsHorizontal = lineMode == .horizontal || lineMode == .both
        let showsVertical = lineMode == .vertical || lineMode == .both

        horizontalGuide.isHidden = !showsHorizontal
        verticalGuide.isHidden = !showsVertical
        verticalMeasurementDragBand.isHidden = !showsVertical
        horizontalMeasurementDragBand.isHidden = !showsHorizontal
        topLabel.isHidden = !showsHorizontal
        bottomLabel.isHidden = !showsHorizontal
        leftLabel.isHidden = !showsVertical
        rightLabel.isHidden = !showsVertical
    }

    private func updateMargins() {
        let horizontalVisible = !horizontalGuide.isHidden
        let verticalVisible = !verticalGuide.isHidden
        let verticalX = verticalGuideX ?? bounds.midX
        let horizontalY = horizontalGuideY ?? bounds.midY

        let path = UIBezierPath()

        if verticalVisible {
            path.move(to: CGPoint(x: bounds.minX, y: 28))
            path.addLine(to: CGPoint(x: verticalX, y: 28))
            path.move(to: CGPoint(x: verticalX, y: 28))
            path.addLine(to: CGPoint(x: bounds.maxX, y: 28))

            leftLabel.text = measurementText(abs(verticalX - bounds.minX))
            rightLabel.text = measurementText(abs(bounds.maxX - verticalX))
            leftLabel.center = CGPoint(x: (bounds.minX + verticalX) / 2, y: 28)
            rightLabel.center = CGPoint(x: (verticalX + bounds.maxX) / 2, y: 28)
        }

        if horizontalVisible {
            path.move(to: CGPoint(x: 28, y: bounds.minY))
            path.addLine(to: CGPoint(x: 28, y: horizontalY))
            path.move(to: CGPoint(x: 28, y: horizontalY))
            path.addLine(to: CGPoint(x: 28, y: bounds.maxY))

            topLabel.text = measurementText(abs(horizontalY - bounds.minY))
            bottomLabel.text = measurementText(abs(bounds.maxY - horizontalY))
            topLabel.center = CGPoint(x: 28, y: (bounds.minY + horizontalY) / 2)
            bottomLabel.center = CGPoint(x: 28, y: (horizontalY + bounds.maxY) / 2)
        }

        marginLayer.path = path.cgPath
        [leftLabel, rightLabel, topLabel, bottomLabel].forEach {
            $0.clamp(to: bounds.insetBy(dx: 12, dy: 12))
        }
    }

    @objc private func handleVerticalPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        gesture.setTranslation(.zero, in: self)
        verticalGuideX = clamp((verticalGuideX ?? bounds.midX) + translation.x, min: bounds.minX, max: bounds.maxX)
        setNeedsLayout()
    }

    @objc private func handleHorizontalPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        gesture.setTranslation(.zero, in: self)
        horizontalGuideY = clamp((horizontalGuideY ?? bounds.midY) + translation.y, min: bounds.minY, max: bounds.maxY)
        setNeedsLayout()
    }

    @objc private func handleToolbarPan(_ gesture: UIPanGestureRecognizer) {
        guard let toolbarLeadingConstraint, let toolbarTopConstraint, let toolbarWidthConstraint, let toolbarHeightConstraint else {
            return
        }

        let translation = gesture.translation(in: self)
        gesture.setTranslation(.zero, in: self)

        let targetWidth = toolbarWidthConstraint.constant
        let targetHeight = toolbarHeightConstraint.constant
        var nextLeading = toolbarLeadingConstraint.constant
        var nextTop = toolbarTopConstraint.constant + translation.y

        if isToolbarVisible {
            nextLeading += translation.x
        } else {
            nextLeading = 0
        }

        let clampedOrigin = clampedToolbarOrigin(
            x: nextLeading,
            y: nextTop,
            size: CGSize(width: targetWidth, height: targetHeight),
            hidden: !isToolbarVisible
        )

        toolbarLeadingConstraint.constant = clampedOrigin.x
        toolbarTopConstraint.constant = clampedOrigin.y

        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            UIView.animate(withDuration: 0.12) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }

    @objc private func handleMovementButtonTouchDown(_ sender: UIButton) {
        guard let direction = MovementDirection(rawValue: sender.tag) else { return }
        beginContinuousMovement(direction)
    }

    @objc private func handleMovementButtonTouchUp(_ sender: UIButton) {
        stopContinuousMovement()
    }

    private func adjustGridSize(by delta: CGFloat) {
        gridOverlayView.gridSize = max(1, min(120, gridOverlayView.gridSize + delta))
        updateGridState()
    }

    private func moveHorizontalGuide(by delta: CGFloat) {
        horizontalGuideY = clamp((horizontalGuideY ?? bounds.midY) + delta, min: bounds.minY, max: bounds.maxY)
        setNeedsLayout()
    }

    private func moveVerticalGuide(by delta: CGFloat) {
        verticalGuideX = clamp((verticalGuideX ?? bounds.midX) + delta, min: bounds.minX, max: bounds.maxX)
        setNeedsLayout()
    }

    private func setGuideMode(_ mode: MeasurementLineMode, source: UISegmentedControl? = nil) {
        lineMode = mode
        if source !== axisControl {
            axisControl.selectedSegmentIndex = mode.rawValue
        }
        if source !== movementAxisControl {
            movementAxisControl.selectedSegmentIndex = mode.rawValue
        }
        updateGuideVisibility()
        setNeedsLayout()
    }

    private func performMove(_ direction: MovementDirection) -> Bool {
        switch direction {
        case .up:
            let current = horizontalGuideY ?? bounds.midY
            let next = clamp(current - movementStep, min: bounds.minY, max: bounds.maxY)
            guard next != current else { return false }
            moveHorizontalGuide(by: next - current)
        case .down:
            let current = horizontalGuideY ?? bounds.midY
            let next = clamp(current + movementStep, min: bounds.minY, max: bounds.maxY)
            guard next != current else { return false }
            moveHorizontalGuide(by: next - current)
        case .left:
            let current = verticalGuideX ?? bounds.midX
            let next = clamp(current - movementStep, min: bounds.minX, max: bounds.maxX)
            guard next != current else { return false }
            moveVerticalGuide(by: next - current)
        case .right:
            let current = verticalGuideX ?? bounds.midX
            let next = clamp(current + movementStep, min: bounds.minX, max: bounds.maxX)
            guard next != current else { return false }
            moveVerticalGuide(by: next - current)
        }
        return true
    }

    private func beginContinuousMovement(_ direction: MovementDirection) {
        stopContinuousMovement()
        repeatDirection = direction
        _ = performMove(direction)

        movementBootstrapTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.movementRepeatTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] timer in
                guard let self, let repeatDirection = self.repeatDirection else {
                    timer.invalidate()
                    return
                }
                let didMove = self.performMove(repeatDirection)
                if !didMove {
                    self.stopContinuousMovement()
                }
            }
            if let movementRepeatTimer = self.movementRepeatTimer {
                RunLoop.main.add(movementRepeatTimer, forMode: .common)
            }
        }

        if let movementBootstrapTimer = movementBootstrapTimer {
            RunLoop.main.add(movementBootstrapTimer, forMode: .common)
        }
    }

    private func stopContinuousMovement() {
        movementBootstrapTimer?.invalidate()
        movementRepeatTimer?.invalidate()
        movementBootstrapTimer = nil
        movementRepeatTimer = nil
        repeatDirection = nil
    }

    private func updateGridState() {
        gridOverlayView.isHidden = !isGridVisible
        gridOverlayView.overlayOpacity = gridOpacity
        gridOverlayView.primaryColor = gridColor
        gridSizeLabel.setTitle(String(format: "%.0fpt", gridOverlayView.gridSize), for: .normal)
        gridToggleSwitch.isOn = isGridVisible
        movementGridToggleSwitch.isOn = isGridVisible
        gridToggleSwitch.onTintColor = gridColor
        movementGridToggleSwitch.onTintColor = gridColor
        gridOpacityButton.setTitle(String(format: "Opacity %.1f", gridOpacity), for: .normal)
        movementGridOpacityButton.setTitle(String(format: "Opacity %.1f", gridOpacity), for: .normal)
    }

    private func toggleToolbarVisibility() {
        if isToolbarVisible {
            hideToolbarIntoCompactState()
        } else {
            showToolbarAfterCollapse()
        }
    }

    private func toggleInlineMovementControls(animated: Bool) {
        isMovementControlsVisible.toggle()
        let updates = {
            self.detailLabel.isHidden = self.isMovementControlsVisible
            self.updateInlineMovementState()
            self.layoutIfNeeded()
        }

        if animated {
            UIView.transition(with: self.controlsPageView, duration: 0.18, options: .transitionCrossDissolve, animations: updates)
        } else {
            updates()
        }
    }

    private func updateInlineMovementState() {
        gridSectionContainerView?.isHidden = isMovementControlsVisible
        movementInlineContainerView?.isHidden = !isMovementControlsVisible
        movementCenterView.isHidden = !isMovementControlsVisible
        movementModeButton.backgroundColor = isMovementControlsVisible
            ? UIColor.white.withAlphaComponent(0.24)
            : UIColor.white.withAlphaComponent(0.12)
        movementModeButton.setImage(
            UIImage(systemName: isMovementControlsVisible
                ? "rectangle.and.hand.point.up.left.fill"
                : "arrow.up.and.down.and.arrow.left.and.right"),
            for: .normal
        )
        movementModeButton.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: isMovementControlsVisible ? 12 : 14, weight: .semibold),
            forImageIn: .normal
        )
    }

    private func hideToolbarIntoCompactState() {
        stopContinuousMovement()
        isToolbarVisible = false
        isMovementControlsVisible = false
        updateToolbarPage()
        updateInlineMovementState()
        compactOpenButton.isHidden = true
        controlsPageView.isHidden = true
        movementPageView.isHidden = true
        applyToolbarVisibility(animated: true) { [weak self] in
            self?.compactOpenButton.isHidden = false
        }
    }

    private func showToolbarAfterCollapse() {
        compactOpenButton.isHidden = true
        isToolbarVisible = true
        ensureToolbarVisibleWithinScreen(animated: false)
        applyToolbarVisibility(animated: true) { [weak self] in
            guard let self else { return }
            self.updateToolbarPage()
            self.updateInlineMovementState()
        }
    }

    private func setToolbarPage(_ page: ToolbarPage, animated: Bool) {
        toolbarPage = page
        let update = {
            self.updateToolbarPage()
        }
        if animated {
            UIView.transition(with: toolbarView.contentView, duration: 0.18, options: .transitionCrossDissolve, animations: update)
        } else {
            update()
        }
    }

    private func updateToolbarPage() {
        controlsPageView.isHidden = !isToolbarVisible
        movementPageView.isHidden = true
        compactOpenButton.isHidden = isToolbarVisible
        let collapseImage = isToolbarVisible ? "chevron.left.circle.fill" : "chevron.right.circle.fill"
        collapseButton.setImage(UIImage(systemName: collapseImage), for: .normal)
        compactOpenButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
    }

    private func updateToolbarVisibilityState() {
        toolbarBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(isToolbarVisible ? 0.56 : 0.12)
        toolbarView.layer.cornerRadius = isToolbarVisible ? 16 : 20
        toolbarView.layer.maskedCorners = isToolbarVisible
            ? [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMinXMaxYCorner]
            : [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }

    private func applyToolbarVisibility(animated: Bool, completion: (() -> Void)? = nil) {
        guard let toolbarLeadingConstraint, let toolbarTopConstraint, let toolbarWidthConstraint, let toolbarHeightConstraint else {
            completion?()
            return
        }

        let expandedHeight = expandedToolbarHeight()
        let targetWidth: CGFloat = isToolbarVisible ? 340 : 40
        let targetHeight: CGFloat = isToolbarVisible ? expandedHeight : 40

        let clampedOrigin = clampedToolbarOrigin(
            x: toolbarLeadingConstraint.constant,
            y: toolbarTopConstraint.constant,
            size: CGSize(width: targetWidth, height: targetHeight),
            hidden: !isToolbarVisible
        )

        toolbarLeadingConstraint.constant = clampedOrigin.x
        toolbarTopConstraint.constant = clampedOrigin.y
        toolbarWidthConstraint.constant = isToolbarVisible ? 340 : 40
        toolbarHeightConstraint.constant = targetHeight
        updateToolbarVisibilityState()

        let animations = {
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.24,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.2,
                options: [.beginFromCurrentState, .allowUserInteraction],
                animations: animations,
                completion: { _ in completion?() }
            )
        } else {
            animations()
            completion?()
        }
    }

    private func expandedToolbarHeight() -> CGFloat {
        guard let controlsPageStack else { return 180 }
        if let defaultExpandedToolbarHeight {
            return defaultExpandedToolbarHeight
        }

        let targetSize = CGSize(width: 340, height: UIView.layoutFittingCompressedSize.height)
        let controlsHeight = controlsPageStack.systemLayoutSizeFitting(targetSize).height + 24
        let resolvedHeight = max(controlsHeight, 180)
        defaultExpandedToolbarHeight = resolvedHeight
        return resolvedHeight
    }

    private func resetGuidesToCenter(animated: Bool) {
        verticalGuideX = bounds.midX
        horizontalGuideY = bounds.midY
        let updates = {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: updates)
        } else {
            updates()
        }
    }

    private func rebuildMenus() {
        lineColorButton.menu = UIMenu(children: accentOptions.map { option in
            UIAction(title: option.title, state: option.color.isEqual(lineColor) ? .on : .off, handler: { [weak self] _ in
                self?.lineColor = option.color
                self?.updateMeasurementAppearance()
                self?.rebuildMenus()
            })
        })
        movementLineColorButton.menu = lineColorButton.menu

        gridColorButton.menu = UIMenu(children: accentOptions.map { option in
            UIAction(title: option.title, state: option.color.isEqual(gridColor) ? .on : .off, handler: { [weak self] _ in
                self?.gridColor = option.color
                self?.updateMeasurementAppearance()
                self?.updateGridState()
                self?.rebuildMenus()
            })
        })
        movementGridColorButton.menu = gridColorButton.menu

        let opacityValues = stride(from: 0.1, through: 1.0, by: 0.1).map { CGFloat((Double($0) * 10).rounded() / 10) }

        lineOpacityButton.menu = UIMenu(children: opacityValues.map { value in
            UIAction(title: String(format: "%.1f", value), state: abs(value - measurementOpacity) < 0.001 ? .on : .off, handler: { [weak self] _ in
                self?.measurementOpacity = value
                self?.updateMeasurementAppearance()
                self?.rebuildMenus()
            })
        })
        movementLineOpacityButton.menu = lineOpacityButton.menu

        gridOpacityButton.menu = UIMenu(children: opacityValues.map { value in
            UIAction(title: String(format: "%.1f", value), state: abs(value - gridOpacity) < 0.001 ? .on : .off, handler: { [weak self] _ in
                self?.gridOpacity = value
                self?.updateGridState()
                self?.rebuildMenus()
            })
        })
        movementGridOpacityButton.menu = gridOpacityButton.menu

        let quickGridValues: [CGFloat] = [4, 6, 8, 10, 12, 16, 20, 24, 28, 32, 40, 48, 56, 64]
        gridSizeLabel.menu = UIMenu(children: quickGridValues.map { value in
            UIAction(title: String(format: "%.0fpt", value), state: abs(value - gridOverlayView.gridSize) < 0.001 ? .on : .off, handler: { [weak self] _ in
                self?.gridOverlayView.gridSize = value
                self?.updateGridState()
                self?.rebuildMenus()
            })
        })

        let movementSteps = stride(from: 0.1, through: 1.0, by: 0.1).map { CGFloat((Double($0) * 10).rounded() / 10) }
        let movementStepMenu = UIMenu(children: movementSteps.map { value in
            UIAction(title: String(format: "%.1fpt", value), state: abs(value - movementStep) < 0.001 ? .on : .off, handler: { [weak self] _ in
                self?.movementStep = value
                self?.updateMovementStepAppearance()
                self?.rebuildMenus()
            })
        })
        movementStepButton.menu = movementStepMenu
        movementCenterLabel.menu = movementStepMenu
    }

    private func updateMeasurementAppearance() {
        marginLayer.strokeColor = lineColor.withAlphaComponent(measurementOpacity).cgColor
        verticalGuide.accentColor = lineColor.withAlphaComponent(measurementOpacity)
        horizontalGuide.accentColor = lineColor.withAlphaComponent(measurementOpacity)
        [leftLabel, rightLabel, topLabel, bottomLabel].forEach { label in
            label.accentColor = lineColor
            label.alpha = 1
        }
        gridOverlayView.primaryColor = gridColor
        gridOverlayView.overlayOpacity = gridOpacity
        lineColorButton.backgroundColor = lineColor.withAlphaComponent(0.9)
        lineColorButton.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        movementLineColorButton.backgroundColor = lineColor.withAlphaComponent(0.9)
        movementLineColorButton.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        gridColorButton.backgroundColor = gridColor.withAlphaComponent(0.9)
        gridColorButton.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        movementGridColorButton.backgroundColor = gridColor.withAlphaComponent(0.9)
        movementGridColorButton.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        lineOpacityButton.setTitle(String(format: "Opacity %.1f", measurementOpacity), for: .normal)
        movementLineOpacityButton.setTitle(String(format: "Opacity %.1f", measurementOpacity), for: .normal)
        gridOpacityButton.setTitle(String(format: "Opacity %.1f", gridOpacity), for: .normal)
        movementGridOpacityButton.setTitle(String(format: "Opacity %.1f", gridOpacity), for: .normal)
        updateMovementStepAppearance()
    }

    private func updateMovementStepAppearance() {
        movementStepButton.setTitle(String(format: "Step %.1fpt", movementStep), for: .normal)
        movementCenterLabel.setTitle(String(format: "%.1f", movementStep), for: .normal)
    }

    private func ensureToolbarVisibleWithinScreen(animated: Bool) {
        guard let toolbarLeadingConstraint, let toolbarTopConstraint, let toolbarWidthConstraint, let toolbarHeightConstraint else {
            return
        }

        let clampedOrigin = clampedToolbarOrigin(
            x: toolbarLeadingConstraint.constant,
            y: toolbarTopConstraint.constant,
            size: CGSize(width: toolbarWidthConstraint.constant, height: toolbarHeightConstraint.constant),
            hidden: !isToolbarVisible
        )

        guard clampedOrigin.x != toolbarLeadingConstraint.constant || clampedOrigin.y != toolbarTopConstraint.constant else {
            return
        }

        toolbarLeadingConstraint.constant = clampedOrigin.x
        toolbarTopConstraint.constant = clampedOrigin.y

        let updates = {
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.16, animations: updates)
        } else {
            updates()
        }
    }

    private func clampedToolbarOrigin(x: CGFloat, y: CGFloat, size: CGSize, hidden: Bool) -> CGPoint {
        let safeInsets = safeAreaInsets
        let topMargin = safeInsets.top + 12
        let bottomMargin = safeInsets.bottom + 12
        let minX: CGFloat = hidden ? 0 : 0
        let maxX = max(minX, bounds.width - size.width)
        let minY = topMargin
        let maxY = max(minY, bounds.height - bottomMargin - size.height)

        return CGPoint(
            x: hidden ? 0 : clamp(x, min: minX, max: maxX),
            y: clamp(y, min: minY, max: maxY)
        )
    }

    private func measurementText(_ value: CGFloat) -> String {
        String(format: "%.1fpt", value)
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minValue), maxValue)
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === toolbarPanGesture else { return true }

        if !isToolbarVisible {
            return true
        }

        let location = gestureRecognizer.location(in: toolbarView.contentView)
        guard headerContainerView.frame.contains(location) else {
            return false
        }

        let hitView = toolbarView.contentView.hitTest(location, with: nil)
        return !(hitView is UIControl)
    }
}

private extension UILabel {
    func copyLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.font = font
        label.textColor = textColor
        label.textAlignment = textAlignment
        label.text = text
        return label
    }
}

@MainActor
private final class DSPUIMeasurementGuideHandle: UIView {
    enum Axis {
        case horizontal
        case vertical
    }

    private let lineView = UIView(frame: .zero)
    private let axis: Axis

    var accentColor: UIColor = .systemBlue {
        didSet {
            lineView.backgroundColor = accentColor
            lineView.layer.shadowColor = accentColor.cgColor
        }
    }

    init(axis: Axis) {
        self.axis = axis
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = true

        lineView.backgroundColor = accentColor
        lineView.layer.cornerRadius = 1
        lineView.layer.shadowColor = accentColor.cgColor
        lineView.layer.shadowOpacity = 0.35
        lineView.layer.shadowRadius = 8
        lineView.layer.shadowOffset = .zero
        addSubview(lineView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        switch axis {
        case .horizontal:
            lineView.frame = CGRect(x: 0, y: bounds.midY - 1, width: bounds.width, height: 2)
        case .vertical:
            lineView.frame = CGRect(x: bounds.midX - 1, y: 0, width: 2, height: bounds.height)
        }
    }
}

@MainActor
final class DSPUIMeasurementLabelView: UIView {
    private let label = UILabel(frame: .zero)

    var accentColor: UIColor = .systemBlue {
        didSet {
            layer.borderColor = accentColor.cgColor
            label.textColor = accentColor
        }
    }

    var text: String? {
        didSet {
            label.text = text
            label.sizeToFit()
            bounds.size = CGSize(width: label.bounds.width + 12, height: label.bounds.height + 6)
            label.frame = CGRect(x: 6, y: 3, width: label.bounds.width, height: label.bounds.height)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 6
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = accentColor.cgColor
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        label.textColor = accentColor
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func clamp(to rect: CGRect) {
        center = CGPoint(
            x: Swift.min(Swift.max(center.x, rect.minX + bounds.width / 2), rect.maxX - bounds.width / 2),
            y: Swift.min(Swift.max(center.y, rect.minY + bounds.height / 2), rect.maxY - bounds.height / 2)
        )
    }
}
