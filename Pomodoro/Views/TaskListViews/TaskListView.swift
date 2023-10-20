//
//  TaskListView.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/13/23.
//

import SwiftUI
import CoreData

struct TaskListView: UIViewControllerRepresentable {
    @Environment(\.managedObjectContext) private var viewContext

    func makeUIViewController(context: Context) -> UIViewController {
        TaskListViewController(viewContext: viewContext)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

class TaskListViewController: UIViewController, NSFetchedResultsControllerDelegate {
    enum Section {
        case projects
        case tasks
    }

    enum ListItem: Hashable {
        case task(NSManagedObjectID)
        case projectsPlaceholder
    }

    private var collectionView: UICollectionView! = nil
    private var diffableDataSource: UICollectionViewDiffableDataSource<Section, ListItem>! = nil

    private var todaysTasksController: NSFetchedResultsController<TaskNote>! = nil
    private var viewContext: NSManagedObjectContext

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

        view = collectionView
    }

    private struct LayoutMetrics {
        static let horizontalMargin = 16.0
        static let sectionSpacing = 10.0
        static let headerHeight = 20.0
    }

    private func configureLayout() {
        let layout = UICollectionViewCompositionalLayout { [unowned self] _, layoutEnvironment in
            return createTasksLayout(layoutEnvironment)
        }
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleHeight]
        collectionView.allowsSelection = false
        collectionView.allowsFocus = true
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

    private func configureDataSource() {
        // swiftlint:disable:next line_length
        let diffableDataSource = UICollectionViewDiffableDataSource<Section, ListItem>(collectionView: collectionView) { [unowned self] collectionView, indexPath, identifier -> UICollectionViewCell? in
            switch identifier {
            case let .task(identifier):
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
        diffableDataSource.supplementaryViewProvider = { collectionView, _, indexPath -> UICollectionReusableView? in
            return collectionView.dequeueConfiguredReusableSupplementary(using: self.headerCellRegistration,
                                                                         for: indexPath)
        }

        self.diffableDataSource = diffableDataSource
        collectionView.dataSource = self.diffableDataSource
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
        .init { cell, _, item in
            guard let taskItem = item as? TaskNote,
                  let viewContext = taskItem.managedObjectContext else {
                return
            }
            cell.contentConfiguration = UIHostingConfiguration {
                TaskCell(taskItem: taskItem)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }()

    private var projectsStackCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, NSNull> = {
        .init { cell, _, _ in
            cell.contentConfiguration = UIHostingConfiguration {
                ProjectStack()
            }
//            cell.layer.speed = 0.2
            cell.contentView.clipsToBounds = false
            cell.clipsToBounds = false
            cell.contentView.layer.masksToBounds = false
            cell.layer.masksToBounds = false
        }
    }()

    private func configureFetchControllers() {
        let todaysTasksFetchRequest = NSFetchRequest<TaskNote>(entityName: "TaskNote")
        todaysTasksFetchRequest.sortDescriptors = [
            SortDescriptor(\TaskNote.order, order: .reverse),
            SortDescriptor(\TaskNote.timestamp, order: .forward)
        ].map { descriptor in NSSortDescriptor(descriptor) }
        todaysTasksFetchRequest.predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@",
                                                        Calendar.current.startOfDay(for: Date()) as CVarArg,
                                                        Calendar.current.startOfDay(for: Date() + 86400) as CVarArg)

        todaysTasksController = NSFetchedResultsController(fetchRequest: todaysTasksFetchRequest,
                                                           managedObjectContext: viewContext,
                                                           sectionNameKeyPath: nil,
                                                           cacheName: nil)
        todaysTasksController.delegate = self

        do {
            try todaysTasksController.performFetch()
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
}

extension TaskListViewController {

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

        let fetchedTasks = todaysTasksController.fetchedObjects?.map { obj in ListItem.task(obj.objectID) } ?? []
        snapshot.appendItems(fetchedTasks, toSection: .tasks)

        dataSource.apply(snapshot, animatingDifferences: true)
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
            TaskListView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .previewDisplayName("TaskList UIKit")
                .navigationTitle("Tisksss 🐍")
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
                        TaskListView()
                            .navigationTitle("List")
                    }, pomoTimer: pomoTimer)
                }
                .background(Color(hex: 0x02201F))
            }
        }
    }
}
