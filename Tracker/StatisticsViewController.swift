import UIKit

class StatisticsViewController: UIViewController {
    private let dataStores: TrackerDataStores

    init(dataStores: TrackerDataStores) {
        self.dataStores = dataStores
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preloadStatisticsFromStores()
        view.backgroundColor = .systemBackground
        title = "Статистика"
    }

    private func preloadStatisticsFromStores() {
        _ = dataStores.recordStore.fetchAll()
    }
}
