//
//  TaskListView.swift
//  Pomodoro
//
//  Created by Porter Glines on 10/13/23.
//

import SwiftUI

struct TaskListView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        TaskListViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

private struct StaticData {
    lazy var numbers = (0..<100).map { _ in DataNumber(val: Int.random(in: 1...32))}
}

private struct DataNumber: Hashable {
    var val: Int
    var id = UUID()
}

class TaskListViewController: UIViewController {
    private typealias ListItem = DataNumber
    private var data = StaticData()

    private var collectionView: UICollectionView!
    private var diffableDataSource: UICollectionViewDiffableDataSource<Int, ListItem>!

    override func loadView() {
        super.loadView()
        setUpCollectionView()
        view = collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Task List"
    }

    private struct LayoutMetrics {
        static let horizontalMargin = 16.0
        static let sectionSpacing = 10.0
    }

    private func setUpCollectionView() {
        let layout = UICollectionViewCompositionalLayout { [unowned self] _, layoutEnvironment in
            return createTaskSection(layoutEnvironment)
        }

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.allowsSelection = false

        // swiftlint:disable:next line_length
        let diffableDataSource = UICollectionViewDiffableDataSource<Int, ListItem>(collectionView: collectionView) { collectionView, indexPath, _ -> UICollectionViewCell? in
            let item = self.data.numbers[indexPath.item]
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.taskCellRegistration,
                                                                    for: indexPath,
                                                                    item: item)
            return cell
        }
        self.diffableDataSource = diffableDataSource
        collectionView.dataSource = self.diffableDataSource
        updateSnapshot()
    }

    private func createTaskSection(_ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.backgroundColor = .clear
        let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        section.contentInsets = .zero
        section.contentInsets.leading = LayoutMetrics.horizontalMargin
        section.contentInsets.trailing = LayoutMetrics.horizontalMargin
        section.contentInsets.bottom = LayoutMetrics.sectionSpacing
        return section
    }

    private var taskCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, ListItem> = {
        .init { cell, _, item in
            cell.contentConfiguration = UIHostingConfiguration {
                Cell(data: item.val)
            }
        }
    }()

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ListItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(data.numbers)

        diffableDataSource.apply(snapshot, animatingDifferences: true)
    }
}

struct Cell: View {
    let data: Int
    @State var isExpanded: Bool = false
    @State var unexpandTask: Task<(), Never>?

    var body: some View {
        Text("I'm a cell \(data), click me ")
            .frame(minHeight: isExpanded ? 200 : 20)
            .background(Color(hex: 0xF3FCDC * data))
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
