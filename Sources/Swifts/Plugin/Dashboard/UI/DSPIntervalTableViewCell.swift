import UIKit

class DSPIntervalTableViewCell: UITableViewCell {
    let graph = DSPIntervalView(frame: .null)
    private let collapsedGraphSize = CGSize(width: 64, height: 36)
    private let expandedGraphSize = CGSize(width: 180, height: 72)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        graph.frame = .init(origin: .zero, size: collapsedGraphSize)
        accessoryView = graph
        selectionStyle = .none
        textLabel?.textColor = .white
        textLabel?.adjustsFontSizeToFitWidth = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDurations(_ durations: [TimeInterval]) {
        graph.reload(durations: durations)
    }

    func setExpanded(_ isExpanded: Bool, animated: Bool) {
        let size = isExpanded ? expandedGraphSize : collapsedGraphSize
        let updates = {
            self.graph.frame = CGRect(origin: .zero, size: size)
            self.accessoryView = self.graph
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.28,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.2,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: updates
            )
        } else {
            updates()
        }
    }
}
