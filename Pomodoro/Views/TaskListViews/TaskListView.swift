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
        case tasks
    }
    private typealias ListItemID = NSManagedObjectID
    private typealias ListItem = NSManagedObject

    private var collectionView: UICollectionView! = nil
    private var diffableDataSource: UICollectionViewDiffableDataSource<Section, ListItemID>! = nil

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

        configureFetchController()

        view = collectionView
        title = "Task List"
    }

    private struct LayoutMetrics {
        static let horizontalMargin = 16.0
        static let sectionSpacing = 10.0
    }

    private func configureLayout() {
        let layout = UICollectionViewCompositionalLayout { [unowned self] _, layoutEnvironment in
            return createTasksLayout(layoutEnvironment)
        }
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleHeight]
        collectionView.allowsSelection = false
    }

    private func createTasksLayout(_ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.backgroundColor = .clear
        let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        section.contentInsets = .zero
        section.contentInsets.leading = LayoutMetrics.horizontalMargin
        section.contentInsets.trailing = LayoutMetrics.horizontalMargin
        section.contentInsets.bottom = LayoutMetrics.sectionSpacing
        return section
    }

    private func configureDataSource() {
        // swiftlint:disable:next line_length
        let diffableDataSource = UICollectionViewDiffableDataSource<Section, ListItemID>(collectionView: collectionView) { collectionView, indexPath, identifier -> UICollectionViewCell? in
            let item = self.viewContext.object(with: identifier)
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.taskCellRegistration,
                                                                    for: indexPath,
                                                                    item: item)
            return cell
        }
        self.diffableDataSource = diffableDataSource
        collectionView.dataSource = self.diffableDataSource
    }

    private var taskCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, ListItem> = {
        .init { cell, _, item in
            guard let taskItem = item as? TaskNote,
                  let viewContext = taskItem.managedObjectContext else {
                return
            }
            cell.contentConfiguration = UIHostingConfiguration {
                Cell(data: taskItem.text ?? "", id: taskItem.id)
                    .id(taskItem.id)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }()

    private func configureFetchController() {
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
        // swiftlint:disable:next line_length
        guard let dataSource = collectionView.dataSource as? UICollectionViewDiffableDataSource<Section, NSManagedObjectID> else {
            assertionFailure("Collection view data source not available")
            return
        }

        var snapshot = snapshot as NSDiffableDataSourceSnapshot<Section, NSManagedObjectID>
        let currentSnapshot = dataSource.snapshot() as NSDiffableDataSourceSnapshot<Section, NSManagedObjectID>

        let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers.compactMap { itemIdentifier in
            guard let index = snapshot.indexOfItem(itemIdentifier),
                  let currentIndex = currentSnapshot.indexOfItem(itemIdentifier),
                  index == currentIndex else {
                return nil
            }
            // swiftlint:disable:next line_length
            guard let existingObjects = try? todaysTasksController.managedObjectContext.existingObject(with: itemIdentifier),
                  existingObjects.isUpdated else {
                return nil
            }
            return itemIdentifier
        }

        snapshot.reloadItems(reloadIdentifiers)
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

struct Cell: View {
    @Environment(\.managedObjectContext) private var viewContext

    let data: String
    let id: ObjectIdentifier
    @State var isExpanded: Bool = false
    @State var unexpandTask: Task<(), Never>?

    var body: some View {
        VStack(alignment: .leading) {
            Text("I'm a cell \(data)")
            Text(id.debugDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
            .frame(minHeight: isExpanded ? 200 : 20)
            .background(Color(hex: 0xF3FCDC * data.count))
            .clipShape(.rect(cornerRadius: 4.0))
            .animation(.bouncy(duration: 1), value: isExpanded)
            .onTapGesture {
                withAnimation {
                    isExpanded = true
                }
                unexpandTask?.cancel()

                unexpandTask = Task {
                    try? await Task.sleep(for: .seconds(3))
                    if !Task.isCancelled {
                        withAnimation {
                            isExpanded = false
                        }
                    }
                }

                TasksData.addTask("New task added to view context", context: viewContext)
            }
    }
}

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
                    }, pomoTimer: pomoTimer)
                }
                .background(Color(hex: 0x02201F))
            }
        }
    }
}
