//
//  TaskListCollectionView.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/13/23.
//

import SwiftUI
import CoreData
import Combine
import OSLog

struct TaskListCollectionView: UIViewControllerRepresentable {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismissSwipe) private var dismissSwipe

    var showProjects: Bool
    var showPastTasks: Bool
    @ObservedObject var isScrolledToTop: ObservableBool

    func makeUIViewController(context: Context) -> TaskListViewController {
        TaskListViewController(viewContext: viewContext,
                               dismissSwipe: dismissSwipe,
                               showProjects: showProjects,
                               showPastTasks: showPastTasks,
                               isScrolledToTop: isScrolledToTop)
    }

    func updateUIViewController(_ uiViewController: TaskListViewController, context: Context) {
        uiViewController.showProjects = showProjects
        uiViewController.showPastTasks = showPastTasks
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
        case emptyTask
        case taskAdder
        case pastTask(NSManagedObjectID)
        case projectsPlaceholder
    }

    // TODO: implement a solution that doesn't involve a static property
    static var focusedIndexPath: IndexPath?

    private var collectionView: UICollectionView! = nil
    private var diffableDataSource: UICollectionViewDiffableDataSource<Section, ListItem>! = nil

    private var projectStackCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, NSNull>! = nil
    private var taskCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, NSManagedObject>! = nil
    private var taskAdderCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, NSNull>! = nil
    private var taskEmptyCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, NSNull>! = nil
    private var headerCellRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>! = nil
    private var pastHeaderCellRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>! = nil
    private var footerCellRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>! = nil
    private var pastFooterCellRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewCell>! = nil

    private var viewContext: NSManagedObjectContext
    private var todaysTasksController: NSFetchedResultsController<TaskNote>! = nil
    private var pastTasksController: NSFetchedResultsController<TaskNote>! = nil

    private var fetchTask: Task<(), Never>?

    public var showProjects: Bool {
        didSet {
            try? todaysTasksController.performFetch()
        }
    }
    public var showPastTasks: Bool {
        didSet {
            try? pastTasksController.performFetch()
        }
    }

    private var taskSection: Int {
        showProjects ? 1 : 0
    }

    private var isProjectStackCollapsed = ObservableBool(true)
    private var projectStackSubscriber: AnyCancellable?
    private var projectStackIndex: IndexPath?

    private var dismissSwipe: DismissSwipeAction

    /// For some reason there is extra padding on top of keyboard immediately after being shown; this property helps remove the padding
    private var keyboardFirstShownAt: Date?
    private var keyboardOffsetConstraint: NSLayoutConstraint! = nil
    private var keyboardWithoutOffsetConstraint: NSLayoutConstraint! = nil

    private var isScrolledToTop: ObservableBool

    init(viewContext: NSManagedObjectContext,
         dismissSwipe: DismissSwipeAction,
         showProjects: Bool,
         showPastTasks: Bool,
         isScrolledToTop: ObservableBool) {
        self.viewContext = viewContext
        self.dismissSwipe = dismissSwipe
        self.showProjects = showProjects
        self.showPastTasks = showPastTasks
        self.isScrolledToTop = isScrolledToTop
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        configureCellRegistrations()
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

        projectStackSubscriber = isProjectStackCollapsed.$value.sink(receiveValue: { [weak self] isCollapsed in
            guard let self = self else { return }
            if let projectStackIndex, !isCollapsed {
                collectionView.scrollToItem(at: projectStackIndex, at: .centeredVertically, animated: true)
            }
        })
    }

    @objc func handleKeyboardWillShow() {
        Task { @MainActor in
            if let keyboardFirstShownAt {
                if Date.now.timeIntervalSince(keyboardFirstShownAt) < 0.1 {
                    setBottomConstraint(withOffset: true)
                } else {
                    setBottomConstraint(withOffset: false)
                }
            } else {
                keyboardFirstShownAt = .now
            }

            scrollToFocusedIndexPath()
        }
    }

    func scrollToFocusedIndexPath() {
        if let indexPath = TaskListViewController.focusedIndexPath {
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }

    @objc func handleKeyboardWillHide() {
        Task { @MainActor in
            setBottomConstraint(withOffset: false)
            keyboardFirstShownAt = nil
        }
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
            if !showProjects {
                return createProjectsLayout(layoutEnvironment)
            }

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
        collectionView.keyboardDismissMode = .interactive
        collectionView.delegate = self // UIScrollViewDelegate
    }

    private func createProjectsLayout(_ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.backgroundColor = .clear
        let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        section.contentInsets = .zero

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

        let dividerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1.0))
        let divider = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: dividerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)

        section.boundarySupplementaryItems = [headerElement, divider]
        return section
    }

    // swiftlint:disable line_length
    private func configureCellRegistrations() {
        projectStackCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, NSNull> { [unowned self] cell, indexPath, _ in
            projectStackIndex = indexPath
            cell.contentConfiguration = UIHostingConfiguration {
                ProjectStack(isCollapsed: isProjectStackCollapsed)
            }
        }

        taskCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, NSManagedObject> { cell, indexPath, item in
            guard let taskItem = item as? TaskNote,
                  let viewContext = taskItem.managedObjectContext else {
                return
            }
            cell.contentConfiguration = UIHostingConfiguration {
                TaskCell(taskItem: taskItem,
                         initialIndexPath: indexPath,
                         collectionView: self.collectionView,
                         cell: cell,
                         isScrolledToTop: self.isScrolledToTop)
                    .environment(\.managedObjectContext, viewContext)
            }
        }

        taskAdderCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, NSNull> { [unowned self] cell, indexPath, _ in
            cell.contentConfiguration = UIHostingConfiguration {
                let taskItem = TaskNote(context: self.viewContext)
                TaskCell(taskItem: taskItem,
                         isAdderCell: true,
                         initialIndexPath: indexPath,
                         collectionView: self.collectionView,
                         cell: cell,
                         scrollTaskList: self.scrollToFocusedIndexPath)
                    .environment(\.managedObjectContext, self.viewContext)
            }
        }

        taskEmptyCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, NSNull> { cell, _, _ in
            cell.contentConfiguration = UIHostingConfiguration {
                EmptyTasksView()
            }
        }

        headerCellRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: UICollectionView.elementKindSectionHeader) { [unowned self] cell, _, indexPath in
            cell.contentConfiguration = UIHostingConfiguration {
                if indexPath.section == 0 && showProjects {
                    ProjectsHeader(isCollapsed: isProjectStackCollapsed)
                } else {
                    TodaysTasksHeader()
                }
            }
        }

        pastHeaderCellRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: UICollectionView.elementKindSectionHeader) { [unowned self] cell, _, indexPath in
            let identifier = self.diffableDataSource.itemIdentifier(for: indexPath)
            if case let .pastTask(taskItem) = identifier,
               let pastTask = self.viewContext.object(with: taskItem) as? TaskNote {
                cell.contentConfiguration = UIHostingConfiguration {
                    PastTasksHeader(dateString: pastTask.section,
                                    isScrolledToTop: self.isScrolledToTop)
                }
            }
        }

        footerCellRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: UICollectionView.elementKindSectionFooter) { cell, _, _ in
            cell.backgroundColor = .systemFill
        }
        pastFooterCellRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: UICollectionView.elementKindSectionFooter) { cell, _, _ in
        }
    }

    private func configureDataSource() {

        let diffableDataSource = UICollectionViewDiffableDataSource<Section, ListItem>(collectionView: collectionView) { [unowned self] collectionView, indexPath, identifier -> UICollectionViewCell? in
            switch identifier {
            case let .task(identifier), let .pastTask(identifier):
                let item = self.viewContext.object(with: identifier)
                return collectionView.dequeueConfiguredReusableCell(using: self.taskCellRegistration,
                                                                    for: indexPath,
                                                                    item: item)
            case .taskAdder:
                return collectionView.dequeueConfiguredReusableCell(using: self.taskAdderCellRegistration,
                                                                    for: indexPath,
                                                                    item: nil)
            case .emptyTask:
                return collectionView.dequeueConfiguredReusableCell(using: self.taskEmptyCellRegistration,
                                                                    for: indexPath,
                                                                    item: nil)
            case .projectsPlaceholder:
                return collectionView.dequeueConfiguredReusableCell(using: self.projectStackCellRegistration,
                                                                    for: indexPath,
                                                                    item: nil)
            }
        }

        diffableDataSource.supplementaryViewProvider = { [unowned self] collectionView, kind, indexPath -> UICollectionReusableView? in
            let isHeader = kind == UICollectionView.elementKindSectionHeader
            let identifier = diffableDataSource.itemIdentifier(for: indexPath)
            switch identifier {
            case .pastTask:
                return collectionView.dequeueConfiguredReusableSupplementary(using: isHeader ? self.pastHeaderCellRegistration : self.pastFooterCellRegistration,
                                                                             for: indexPath)
            default:
                return collectionView.dequeueConfiguredReusableSupplementary(using: isHeader ? self.headerCellRegistration : self.footerCellRegistration,
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
            let error = error as NSError
            Errors.shared.coreDataError = error
            Logger().error("Failed to fetch entities, CoreData error: \(error), \(error.userInfo)")
        }
    }
}

extension TaskListViewController: NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        fetchTask?.cancel()
        fetchTask = Task { @MainActor in
            guard let dataSource = collectionView.dataSource
                    as? UICollectionViewDiffableDataSource<Section, ListItem> else {
                assertionFailure("Collection view data source with snapshot is not available")
                return
            }

            var snapshot = NSDiffableDataSourceSnapshot<Section, ListItem>()

            if showProjects {
                snapshot.appendSections([.projects])
                snapshot.appendItems([.projectsPlaceholder], toSection: .projects)
            }

            let todaysTasks = todaysTasksController.fetchedObjects?.map { obj in ListItem.task(obj.objectID) } ?? []
            snapshot.appendSections([.tasks])
            snapshot.appendItems(todaysTasks, toSection: .tasks)

            snapshot.appendItems([ListItem.taskAdder], toSection: .tasks)

            if showPastTasks {
                let pastSections = pastTasksController.sections?.map { section in Section.pastTasks(section.name)} ?? []
                snapshot.appendSections(pastSections)
                for pastTaskObj in pastTasksController.fetchedObjects ?? [] {
                    let pastTaskID = pastTaskObj.objectID
                    snapshot.appendItems([.pastTask(pastTaskID)], toSection: .pastTasks(pastTaskObj.section))
                }
            }

            if !Task.isCancelled {
                dataSource.apply(snapshot, animatingDifferences: true)
            }
        }
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
        if let destinationIndexPath, destinationIndexPath.section == taskSection {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }

    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
    }
}

extension TaskListViewController: UICollectionViewDelegate, UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        Task { @MainActor in
            dismissSwipe()

            let scrollOffset = scrollView.contentOffset.y + scrollView.safeAreaInsets.top
            if !isScrolledToTop.value && scrollOffset <= 0 {
                isScrolledToTop.value = true
            } else if isScrolledToTop.value && scrollOffset > 0 {
                isScrolledToTop.value = false
            }
        }
    }
}

#if DEBUG
// swiftlint:disable:next line_length
final class DebugDiffableDataSource<SectionIdentifier, ItemIdentifier>: UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier> where SectionIdentifier: Hashable, ItemIdentifier: Hashable {

    // swiftlint:disable:next identifier_name
    @objc func _collectionView(_ collectionView: UICollectionView,
                               willPerformUpdates updates: [UICollectionViewUpdateItem]) {
    }
}

extension TaskListViewController {
    typealias UICollectionViewDiffableDataSource = DebugDiffableDataSource
}
#endif
