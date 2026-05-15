import UIKit

final class DSPDefaultDebugSettingsVC: UITableViewController {
    private let tools = DSPDefaultDebugTool.allCases
    private let onChange: () -> Void

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = DSPDefaultDebugMenu.sectionTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak self] _ in
                self?.dismiss(animated: true)
            }
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tools.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let tool = tools[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = tool.title
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        cell.accessoryView = checkboxView(isSelected: DSPDefaultDebugToolStore.isVisible(tool))
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tool = tools[indexPath.row]
        let nextValue = !DSPDefaultDebugToolStore.isVisible(tool)
        DSPDefaultDebugToolStore.setVisible(nextValue, for: tool)
        tableView.reloadRows(at: [indexPath], with: .automatic)
        onChange()
    }

    private func checkboxView(isSelected: Bool) -> UIImageView {
        let imageName = isSelected ? "checkmark.square.fill" : "square"
        let imageView = UIImageView(image: UIImage(systemName: imageName))
        imageView.tintColor = .systemBlue
        return imageView
    }
}
