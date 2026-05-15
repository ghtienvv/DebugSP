import UIKit

@MainActor
final class DSPUIGridOverlayView: UIView {
    private let minimumMiddleGap: CGFloat = 8
    private let horizontalLabel = UILabel(frame: .zero)
    private let verticalLabel = UILabel(frame: .zero)

    var gridSize: CGFloat = 28 {
        didSet {
            gridSize = max(4, min(gridSize, 96))
            setNeedsDisplay()
        }
    }

    var overlayOpacity: CGFloat = 0.28 {
        didSet {
            alpha = overlayOpacity
        }
    }

    var primaryColor: UIColor = .systemTeal {
        didSet { setNeedsDisplay() }
    }

    var labelColor: UIColor = .white {
        didSet {
            horizontalLabel.textColor = labelColor
            verticalLabel.textColor = labelColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false

        [horizontalLabel, verticalLabel].forEach { label in
            label.font = .monospacedDigitSystemFont(ofSize: 10, weight: .semibold)
            label.textAlignment = .center
            label.backgroundColor = UIColor.black.withAlphaComponent(0.65)
            label.textColor = labelColor
            label.layer.cornerRadius = 6
            label.layer.cornerCurve = .continuous
            label.clipsToBounds = true
            addSubview(label)
        }

        alpha = overlayOpacity
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext(), bounds.width > 0, bounds.height > 0 else {
            return
        }

        context.clear(rect)
        context.setFillColor(primaryColor.cgColor)

        let lineWidth = 1.0 / UIScreen.main.scale
        drawVerticalGrid(in: context, lineWidth: lineWidth)
        drawHorizontalGrid(in: context, lineWidth: lineWidth)
    }

    private func drawVerticalGrid(in context: CGContext, lineWidth: CGFloat) {
        let screenWidth = bounds.width
        let halfLines = adjustedHalfLineCount(for: screenWidth)
        let middleGap = middleGapSize(for: screenWidth, halfLines: halfLines)

        updateLabel(
            horizontalLabel,
            text: middleGap > 0 ? String(format: "%.0f", middleGap) : nil,
            frame: CGRect(
                x: CGFloat(halfLines) * gridSize,
                y: 72,
                width: middleGap,
                height: 18
            )
        )

        guard halfLines > 0 else { return }
        for lineIndex in 1...halfLines {
            context.fill(CGRect(
                x: CGFloat(lineIndex) * gridSize - lineWidth,
                y: 0,
                width: lineWidth,
                height: bounds.height
            ))
            context.fill(CGRect(
                x: screenWidth - CGFloat(lineIndex) * gridSize,
                y: 0,
                width: lineWidth,
                height: bounds.height
            ))
        }
    }

    private func drawHorizontalGrid(in context: CGContext, lineWidth: CGFloat) {
        let screenHeight = bounds.height
        let halfLines = adjustedHalfLineCount(for: screenHeight)
        let middleGap = middleGapSize(for: screenHeight, halfLines: halfLines)

        updateLabel(
            verticalLabel,
            text: middleGap > 0 ? String(format: "%.0f", middleGap) : nil,
            frame: CGRect(
                x: bounds.width - 56,
                y: CGFloat(halfLines) * gridSize,
                width: 44,
                height: middleGap
            )
        )

        guard halfLines > 0 else { return }
        for lineIndex in 1...halfLines {
            context.fill(CGRect(
                x: 0,
                y: CGFloat(lineIndex) * gridSize - lineWidth,
                width: bounds.width,
                height: lineWidth
            ))
            context.fill(CGRect(
                x: 0,
                y: screenHeight - CGFloat(lineIndex) * gridSize,
                width: bounds.width,
                height: lineWidth
            ))
        }
    }

    private func adjustedHalfLineCount(for screenSize: CGFloat) -> Int {
        guard gridSize > 0 else { return 0 }

        var halfLines = Int(screenSize / (2 * gridSize))
        let gap = middleGapSize(for: screenSize, halfLines: halfLines)
        if gap < minimumMiddleGap, gap > 0 {
            halfLines -= Int(ceil((minimumMiddleGap - gap) / (2 * gridSize)))
        }
        return max(halfLines, 0)
    }

    private func middleGapSize(for screenSize: CGFloat, halfLines: Int) -> CGFloat {
        max(0, screenSize - CGFloat(halfLines * 2) * gridSize)
    }

    private func updateLabel(_ label: UILabel, text: String?, frame: CGRect) {
        guard let text else {
            label.frame = .zero
            label.text = nil
            return
        }

        label.text = text
        label.frame = frame.integral
    }
}