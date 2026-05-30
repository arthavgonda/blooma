import UIKit

class InsightsDetailViewController: UIViewController,
                                    UICollectionViewDelegate,
                                    UICollectionViewDataSource {

    @IBOutlet weak var InsightCollectionView: UICollectionView!

    var category: Category!
    var dataController: DataController!
    var insightDetail: InsightDetail?

    override func viewDidLoad() {
        super.viewDidLoad()
        applyAnimatedBackground(theme: dataController.theme)
        setupCollectionView()
        registerCells()
        loadDetail()
        setupNavigationBar()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = category.title
        navigationItem.rightBarButtonItem = circularIconBarButton(
            systemName: "xmark",
            action: #selector(closeTapped)
        )
        navigationController?.navigationBar.tintColor = dataController.theme.accentPrimary
        navigationItem.largeTitleDisplayMode = .never
    }

    private func setupCollectionView() {
        InsightCollectionView.delegate   = self
        InsightCollectionView.dataSource = self
        InsightCollectionView.backgroundColor = .clear
        InsightCollectionView.alwaysBounceVertical = true
        InsightCollectionView.setCollectionViewLayout(createLayout(), animated: false)
    }

    private func registerCells() {
        InsightCollectionView.register(
            UINib(nibName: "InsightDetailCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "InsightDetailCollectionViewCell"
        )
    }

    private func loadDetail() {
        insightDetail = dataController.loadInsightDetail(
            section: category.id,
            week: dataController.userProfile.gestationalWeek
        )
        InsightCollectionView.reloadData()
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    // MARK: - DataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "InsightDetailCollectionViewCell",
            for: indexPath
        ) as! InsightDetailCollectionViewCell

        if let detail = insightDetail {
            cell.configure(
                with: detail,
                category: category,
                theme: dataController.theme
            )
        }

        return cell
    }

    // MARK: - Layout

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(900)
            )
            let item  = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: itemSize, subitems: [item]
            )
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 0, leading: 0, bottom: 32, trailing: 0
            )
            return section
        }
    }
}
