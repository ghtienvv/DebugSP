import UIKit

class DSPGraphTableViewCell: UITableViewCell {
    let graph = DSPGraphView()
    private let collapsedGraphSize = CGSize(width: 64, height: 36)
    private let expandedGraphSize = CGSize(width: 160, height: 64)

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

    func setData(_ data: [Double]) {
        graph.reload(data: data, capacity: 60)
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
