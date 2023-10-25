//
//  TaskListCollectionView.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/13/23.
//

import SwiftUI
import CoreData

struct TaskListCollectionView: UIViewControllerRepresentable {
    @Environment(\.managedObjectContext) private var viewContext

    func makeUIViewController(context: Context) -> UIViewController {
        TaskListViewController(viewContext: viewContext)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

class TaskListViewController: UIViewController {
    enum Section: Hashable {
        case projects
        case tasks
        case pastTasks(String)
    }

    enum ListItem: Hashable {
        case task(NSManagedObjectID)
        case pastTask(NSManagedObjectID)
        case projectsPlaceholder
    }

    // TODO: implement a solution that doesn't involve a static property
    static var focusedIndexPath: IndexPath?

    private var collectionView: UICollectionView! = nil
    private var diffableDataSource: UICollectionViewDiffableDataSource<Section, ListItem>! = nil

    private var viewContext: NSManagedObjectContext
    private var todaysTasksController: NSFetchedResultsController<TaskNote>! = nil
    private var pastTasksController: NSFetchedResultsController<TaskNote>! = nil

    private var keyboardOffsetConstraint: NSLayoutConstraint! = nil
    private var keyboardWithoutOffsetConstraint: NSLayoutConstraint! = nil

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        configureDataSource()

        configureFetchControllers()
        Task.detached { @MainActor in
            if let todaysTasks = self.todaysTasksController.fetchedObjects {
                TasksData.separateCompleted(todaysTasks, context: self.viewContext)
            }
        }

        let wrappingView = UIView(frame: .zero)
        wrappingView.addSubview(collectionView)
        view = wrappingView

        keyboardWithoutOffsetConstraint = view.keyboardLayoutGuide.topAnchor
            .constraint(equalTo: collectionView.bottomAnchor)
        keyboardOffsetConstraint = view.keyboardLayoutGuide.topAnchor
            .constraint(equalTo: collectionView.bottomAnchor, constant: -34.0)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardWithoutOffsetConstraint
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc func handleKeyboardWillShow() {
        if let focusedIndexPath = TaskListViewController.focusedIndexPath {
            setBottomConstraint(withOffset: true)
            collectionView.scrollToItem(at: focusedIndexPath, at: .bottom, animated: false)
        }
    }

    @objc func handleKeyboardWillHide() {
        setBottomConstraint(withOffset: false)
    }

    private func setBottomConstraint(withOffset: Bool) {
        // Note the order is important to avoid constraint conflicts
        if withOffset {
            keyboardWithoutOffsetConstraint.isActive = !withOffset
            keyboardOffsetConstraint.isActive = withOffset
        } else {
            keyboardOffsetConstraint.isActive = withOffset
            keyboardWithoutOffsetConstraint.isActive = !withOffset
        }
        view.setNeedsUpdateConstraints()
    }

    private struct LayoutMetrics {
        static let horizontalMargin = 16.0
        static let sectionSpacing = 10.0
        static let headerHeight = 20.0
    }

    private func configureLayout() {
        let layout = UICollectionViewCompositionalLayout { [unowned self] section, layoutEnvironment in
            if section == 0 {
                return createProjectsLayout(layoutEnvironment)
            } else {
                return createTasksLayout(layoutEnvironment)
            }
        }
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleHeight]
        collectionView.allowsSelection = false
        collectionView.allowsFocus = true
        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }

    private func createProjectsLayout(_ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.backgroundColor = .clear
        let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        section.contentInsets = .zero
        section.contentInsets.top = -16.0

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .estimated(LayoutMetrics.headerHeight))
        // swiftlint:disable:next line_length
        let headerElement = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        headerElement.contentInsets.leading = LayoutMetrics.horizontalMargin
        headerElement.contentInsets.trailing = LayoutMetrics.horizontalMargin

        section.boundarySupplementaryItems = [headerElement]
        return section
    }

    private func createTasksLayout(_ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.backgroundColor = .clear
        let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        section.contentInsets = .zero
        section.contentInsets.leading = LayoutMetrics.horizontalMargin
        section.contentInsets.trailing = LayoutMetrics.horizontalMargin
        section.contentInsets.bottom = LayoutMetrics.sectionSpacing

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .estimated(LayoutMetrics.headerHeight))
        // swiftlint:disable:next line_length
        let headerElement = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

        section.boundarySupplementaryItems = [headerElement]
        return section
    }

    // swiftlint:disable line_length
    private func configureDataSource() {
        let diffableDataSource = UICollectionViewDiffableDataSource<Section, ListItem>(collectionView: collectionView) { [unowned self] collectionView, indexPath, identifier -> UICollectionViewCell? in
            switch identifier {
            case let .task(identifier), let .pastTask(identifier):
                let item = self.viewContext.object(with: identifier)
                return collectionView.dequeueConfiguredReusableCell(using: self.taskCellRegistration,
                                                                    for: indexPath,
                                                                    item: item)
            case .projectsPlaceholder:
                return collectionView.dequeueConfiguredReusableCell(using: self.projectsStackCellRegistration,
                                                                    for: indexPath,
                                                                    item: nil)
            }
        }

        let pastHeaderCellRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: UICollectionView.elementKindSectionHeader) { [unowned self] cell, _, indexPath in
            let identifier = self.diffableDataSource.itemIdentifier(for: indexPath)
            if case let .pastTask(taskItem) = identifier,
               let pastTask = self.viewContext.object(with: taskItem) as? TaskNote {
                cell.contentConfiguration = UIHostingConfiguration {
                    PastTasksHeader(dateString: pastTask.section)
                }
            }
        }

        diffableDataSource.supplementaryViewProvider = { [unowned self] collectionView, _, indexPath -> UICollectionReusableView? in
            let identifier = diffableDataSource.itemIdentifier(for: indexPath)
            switch identifier {
            case .pastTask:
                return collectionView.dequeueConfiguredReusableSupplementary(using: pastHeaderCellRegistration,
                                                                             for: indexPath)
            default:
                return collectionView.dequeueConfiguredReusableSupplementary(using: self.headerCellRegistration,
                                                                             for: indexPath)
            }
        }

        configureDataSouceReordering(diffableDataSource)

        self.diffableDataSource = diffableDataSource
        collectionView.dataSource = self.diffableDataSource
    }
    // swiftlint:enable line_length

    // swiftlint:disable:next line_length
    private func configureDataSouceReordering(_ diffableDataSource: UICollectionViewDiffableDataSource<Section, ListItem>) {
        diffableDataSource.reorderingHandlers.canReorderItem = { listItem in
            if case .task = listItem {
                return true
            }
            return false
        }

        diffableDataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
            guard let tasksSection = transaction.sectionTransactions.first(where: { section in
                section.sectionIdentifier == .tasks
            }) else {
                return
            }
            let revisedItems = tasksSection.finalSnapshot.items
                .compactMap { listItem in
                    if case let .task(item) = listItem {
                        return item
                    } else {
                        return nil
                    }
                }
                .compactMap { item in self.viewContext.object(with: item) as? TaskNote }

            for reverseIndex in 0..<revisedItems.count {
                revisedItems[revisedItems.count-1-reverseIndex].order =
                    Int16(reverseIndex)
            }

            self.viewContext.perform {
                TasksData.saveContext(self.viewContext, errorMessage: "Error saving reordered tasks")

                Task {
                    try? await Task.sleep(for: .seconds(1.0))
                    if let todaysTasks = self.todaysTasksController.fetchedObjects {
                        TasksData.separateCompleted(todaysTasks, context: self.viewContext)
                    }
                }
            }
        }
    }

    private var headerCellRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell> = {
        .init(elementKind: UICollectionView.elementKindSectionHeader) { cell, _, indexPath in
            cell.contentConfiguration = UIHostingConfiguration {
                if indexPath.section == 0 {
                    ProjectsHeader()
                } else {
                    TodaysTasksHeader()
                }
            }
        }
    }()

    private var taskCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, NSManagedObject> = {
        .init { cell, indexPath, item in
            guard let taskItem = item as? TaskNote,
                  let viewContext = taskItem.managedObjectContext else {
                return
            }
            cell.contentConfiguration = UIHostingConfiguration {
                TaskCell(taskItem: taskItem, indexPath: indexPath)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }()

    private var projectsStackCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, NSNull> = {
        .init { cell, _, _ in
            cell.contentConfiguration = UIHostingConfiguration {
                ProjectStack()
            }
        }
    }()

    private func configureFetchControllers() {
        todaysTasksController = NSFetchedResultsController(fetchRequest: TasksData.todaysTasksRequest,
                                                           managedObjectContext: viewContext,
                                                           sectionNameKeyPath: nil,
                                                           cacheName: nil)
        pastTasksController = NSFetchedResultsController(fetchRequest: TasksData.pastTasksRequest,
                                                           managedObjectContext: viewContext,
                                                           sectionNameKeyPath: #keyPath(TaskNote.section),
                                                           cacheName: nil)
        todaysTasksController.delegate = self
        pastTasksController.delegate = self

        do {
            try todaysTasksController.performFetch()
            try pastTasksController.performFetch()
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
}

extension TaskListViewController: NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let dataSource = collectionView.dataSource
                as? UICollectionViewDiffableDataSource<Section, ListItem> else {
            assertionFailure("Collection view data source with snapshot is not available")
            return
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, ListItem>()
        snapshot.appendSections([.projects, .tasks])
        snapshot.appendItems([.projectsPlaceholder], toSection: .projects)

        let todaysTasks = todaysTasksController.fetchedObjects?.map { obj in ListItem.task(obj.objectID) } ?? []
        snapshot.appendItems(todaysTasks, toSection: .tasks)

        let pastSections = pastTasksController.sections?.map { section in Section.pastTasks(section.name)} ?? []
        snapshot.appendSections(pastSections)
        for pastTaskObj in pastTasksController.fetchedObjects ?? [] {
            let pastTaskID = pastTaskObj.objectID
            snapshot.appendItems([.pastTask(pastTaskID)], toSection: .pastTasks(pastTaskObj.section))
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension TaskListViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return [] }
        guard case let .task(taskItem) = item else { return [] }

        let itemProvider = NSItemProvider()
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = taskItem
        return [dragItem]
    }
}

extension TaskListViewController: UICollectionViewDropDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let destinationIndexPath, destinationIndexPath.section == 1 {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }

    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
    }
}

#if DEBUG
// swiftlint:disable:next line_length
final class DebugDiffableDataSource<SectionIdentifier, ItemIdentifier>: UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier> where SectionIdentifier: Hashable, ItemIdentifier: Hashable {

    // swiftlint:disable:next identifier_name
    @objc func _collectionView(_ collectionView: UICollectionView,
                               willPerformUpdates updates: [UICollectionViewUpdateItem]) {
        print("Diffable data source updates: \(updates)")
    }
}

extension TaskListViewController {
    typealias UICollectionViewDiffableDataSource = DebugDiffableDataSource
}
#endif

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        Wrapper()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .previewDisplayName("Wrapped List")
        NavigationStack {
            TaskListCollectionView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .previewDisplayName("TaskList UIKit")
//                .navigationTitle("Tisksss 🐍")
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Add task") {
                            TasksData.addTask("New task", context: PersistenceController.preview.container.viewContext)
                        }
                    }
                }
        }
    }

    struct Wrapper: View {
        @ObservedObject var pomoTimer: PomoTimer

        init() {
            pomoTimer = PomoTimer(pomos: 4, longBreak: PomoTimer.defaultBreakTime) { status in
                EndTimerHandler.shared.handle(status: status)
            }
            pomoTimer.pause()
            pomoTimer.restoreFromUserDefaults()
        }

        var body: some View {
            NavigationStack {
                VStack {
                    TopButton(destination: {
                        TaskListCollectionView()
                            .navigationTitle("List")
                    }, pomoTimer: pomoTimer)
                }
                .background(Color(hex: 0x02201F))
            }
        }
    }
}
