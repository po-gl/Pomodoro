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

    func makeUIViewController(context: Context) -> TaskListViewController {
        TaskListViewController(viewContext: viewContext,
                               dismissSwipe: dismissSwipe,
                               showProjects: showProjects,
                               showPastTasks: showPastTasks)
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
    static var adderIndexPath: IndexPath?
    static var keyboardFrameEnd: CGRect? = nil
    static var floatingButtonOffset: CGFloat = 51 // 23 + 28 padding

    static var isScrolledToTop = ObservableBool(true)

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
    private var lastFetchDate: Date?
    private var startOfDayFetchSubscriber: AnyCancellable?

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

    private var projectStackCell: UICollectionViewCell?
    private var isProjectStackCollapsed = ObservableBool(true)
    private var projectStackSubscriber: AnyCancellable?
    private var projectStackIndex: IndexPath?

    private var dismissSwipe: DismissSwipeAction

    init(viewContext: NSManagedObjectContext,
         dismissSwipe: DismissSwipeAction,
         showProjects: Bool,
         showPastTasks: Bool) {
        self.viewContext = viewContext
        self.dismissSwipe = dismissSwipe
        self.showProjects = showProjects
        self.showPastTasks = showPastTasks
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = configureLayout()
        configureCollectionView(layout: layout)
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
        view.backgroundColor = UIColor(Color("Background"))

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scrollToAdder),
                                               name: .focusOnAdder,
                                               object: nil)

        projectStackSubscriber = isProjectStackCollapsed.$value
            .delay(for: .seconds(0.1), scheduler: RunLoop.main)
            .sink { [weak self] isCollapsed in
                guard let self = self else { return }
                if !isCollapsed, let navigationController {
                    let inset = navigationController.navigationBar.frame.maxY
                    collectionView.setContentOffset(CGPoint(x: 0, y: -inset), animated: true)
                }
            }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let lastFetchDate, !lastFetchDate.isToday() {
            try? todaysTasksController.performFetch()
            try? pastTasksController.performFetch()
        }

        let startOfDay = Calendar.current.startOfDay(for: Date.now)
        let startOfNextDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        startOfDayFetchSubscriber?.cancel()
        startOfDayFetchSubscriber = Timer.publish(every: startOfNextDay.timeIntervalSinceNow, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                try? todaysTasksController.performFetch()
                try? pastTasksController.performFetch()

                // Reschedule to refresh every 24 hours afterwards
                // this assumes the next day starts in exactly 24 hours
                // but it is unlikely that the app is open for a full 24 hours anyways
                startOfDayFetchSubscriber?.cancel()
                startOfDayFetchSubscriber = Timer.publish(every: 24 * 60 * 60, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in
                        guard let self = self else { return }
                        try? todaysTasksController.performFetch()
                        try? pastTasksController.performFetch()
                    }
            }
    }

    @objc func handleKeyboardWillShow(notification: Notification) {
        Task { @MainActor in
            guard let userInfo = notification.userInfo else { return }
            guard let screen = notification.object as? UIScreen,
                  let keyboardFrameEnd = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            
            let fromCoordinateSpace = screen.coordinateSpace
            let toCoordinateSpace: UICoordinateSpace = view
            let convertedKeyboardFrameEnd = fromCoordinateSpace.convert(keyboardFrameEnd, to: toCoordinateSpace)

            TaskListViewController.keyboardFrameEnd = convertedKeyboardFrameEnd
            scrollToFocusedCell()
        }
    }

    @objc func handleKeyboardWillHide() {
        TaskListViewController.keyboardFrameEnd = nil
    }

    func scrollToFocusedCell() {
        if let indexPath = TaskListViewController.focusedIndexPath {
            scrollTo(indexPath: indexPath)
        }
    }

    @objc func scrollToAdder() {
        if let indexPath = TaskListViewController.adderIndexPath {
            if collectionView.indexPathsForVisibleItems.contains(where: { $0 == indexPath }) {
                scrollTo(indexPath: indexPath)
            } else {
                collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
        }
    }

    func scrollTo(indexPath: IndexPath) {
        var offsetHeight = CGFloat.zero
        if let keyboardFrame = TaskListViewController.keyboardFrameEnd, keyboardFrame.height > 150 {
            offsetHeight = keyboardFrame.height
        } else {
            offsetHeight = TaskListViewController.floatingButtonOffset
            if let tabBarController {
                offsetHeight += tabBarController.tabBar.frame.height
            }
        }

        if let attributes = collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath) {
            guard let screenHeight = view.window?.screen.bounds.height else { return }
            let offset = screenHeight - offsetHeight
            let originY = attributes.frame.origin.y
            let height = attributes.frame.height
            let newContentOffset = originY + height - offset
            // if new offset would be below navigationBar, just return
            if let navigationController, navigationController.navigationBar.frame.maxY + newContentOffset < 0 { return }
            collectionView.setContentOffset(CGPoint(x: 0, y: newContentOffset), animated: true)
        } else {
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }

    private struct LayoutMetrics {
        static let horizontalMargin = 4.0
        static let sectionSpacing = 10.0
        static let headerHeight = 20.0
        static let footerHeight = 18.0
    }

    private func configureLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [unowned self] section, layoutEnvironment in
            if !showProjects {
                return createTasksLayout(layoutEnvironment)
            }
            
            if section == 0 {
                return createProjectsLayout(layoutEnvironment)
            } else {
                return createTasksLayout(layoutEnvironment)
            }
        }
        return layout
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
        section.contentInsets.bottom = LayoutMetrics.sectionSpacing

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .estimated(LayoutMetrics.headerHeight))
        // swiftlint:disable:next line_length
        let headerElement = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

        let dividerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(LayoutMetrics.footerHeight))
        let divider = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: dividerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)

        section.boundarySupplementaryItems = [headerElement, divider]
        return section
    }

    private func configureCollectionView(layout: UICollectionViewCompositionalLayout) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleHeight]
        collectionView.contentInset.bottom += TaskListViewController.floatingButtonOffset
        collectionView.allowsSelection = false
        collectionView.allowsFocus = true
        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.keyboardDismissMode = .interactive
        collectionView.delegate = self // UIScrollViewDelegate
    }

    // swiftlint:disable line_length
    private func configureCellRegistrations() {
        projectStackCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, NSNull> { [unowned self] cell, indexPath, _ in
            projectStackIndex = indexPath
            cell.contentConfiguration = UIHostingConfiguration {
                ProjectStack(isCollapsed: isProjectStackCollapsed)
            }
            projectStackCell = cell
        }

        taskCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, NSManagedObject> { [unowned self] cell, indexPath, item in
            guard let taskItem = item as? TaskNote,
                  let viewContext = taskItem.managedObjectContext else {
                return
            }
            cell.contentConfiguration = UIHostingConfiguration {
                TaskCell(taskItem: taskItem,
                         initialIndexPath: indexPath,
                         collectionView: self.collectionView,
                         cell: cell)
                    .environment(\.managedObjectContext, viewContext)
            }
            .background(Color("Background"))
        }

        taskAdderCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, NSNull> { [unowned self] cell, indexPath, _ in
            TaskListViewController.adderIndexPath = indexPath
            cell.contentConfiguration = UIHostingConfiguration {
                let taskItem = TaskNote(context: self.viewContext)
                TaskCell(taskItem: taskItem,
                         isAdderCell: true,
                         initialIndexPath: indexPath,
                         collectionView: self.collectionView,
                         cell: cell,
                         scrollTaskList: self.scrollToFocusedCell)
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
                    PastTasksHeader(dateString: pastTask.section)
                }
            }
        }

        footerCellRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: UICollectionView.elementKindSectionFooter) { cell, _, _ in
            cell.contentConfiguration = UIHostingConfiguration {
                TodaysTasksFooter()
            }
            .margins(.all, 0)
        }
        pastFooterCellRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: UICollectionView.elementKindSectionFooter) { cell, _, _ in
            cell.contentConfiguration = UIHostingConfiguration {
                Line()
                    .stroke(style: .init(lineWidth: 3, lineCap: .round, dash: [0, 6]))
                    .foregroundStyle(Color(UIColor.systemFill))
                    .frame(height: 1)
            }
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
                if let projectStackCell {
                    // Use cached cell
                    return projectStackCell
                } else {
                    return collectionView.dequeueConfiguredReusableCell(using: self.projectStackCellRegistration,
                                                                        for: indexPath,
                                                                        item: nil)
                }
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
        lastFetchDate = Date.now
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
            if !TaskListViewController.isScrolledToTop.value && scrollOffset <= 0 {
                TaskListViewController.isScrolledToTop.value = true
            } else if TaskListViewController.isScrolledToTop.value && scrollOffset > 0 {
                TaskListViewController.isScrolledToTop.value = false
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
