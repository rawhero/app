import AppKit
import Combine
import UserNotifications
import Core

final class Bar: NSVisualEffectView {
    private weak var zoom: CurrentValueSubject<Window.Zoom, Never>!
    private var subs = Set<AnyCancellable>()
    
    required init?(coder: NSCoder) { nil }
    init(
        url: URL,
        info: CurrentValueSubject<[Window.Info], Never>,
        selected: CurrentValueSubject<[Core.Picture], Never>,
        sort: CurrentValueSubject<Window.Sort, Never>,
        zoom: CurrentValueSubject<Window.Zoom, Never>) {
            self.zoom = zoom
            
            super.init(frame: .zero)
            state = .active
            material = .menu
            
            let title = Text(vibrancy: true)
            
            let sorting = Option(icon: "arrow.up.arrow.down", size: 13)
            sorting.toolTip = "Order photos by"
            sorting
                .click
                .sink {
                    let pop = Sorting(sort: sort)
                    pop.show(relativeTo: sorting.bounds, of: sorting, preferredEdge: .maxY)
                    pop.contentViewController!.view.window!.makeKey()
                }
                .store(in: &subs)
            
            let zooming = NSSegmentedControl(images: ["square.grid.2x2", "rectangle"]
                                                .compactMap {
                                                    .init(systemSymbolName: $0, accessibilityDescription: nil)
                                                        .flatMap {
                                                            $0
                                                                .withSymbolConfiguration(.init(pointSize: 13, weight: .regular)
                                                                                        .applying(.init(hierarchicalColor: .secondaryLabelColor)))
                                                        }
                                                }, trackingMode: .selectOne, target: self, action: #selector(change))
            zooming.translatesAutoresizingMaskIntoConstraints = false
            zooming.segmentDistribution = .fit
            zooming.segmentStyle = .rounded
            
            let delete = Option(icon: "trash", size: 13)
            delete.toolTip = "Delete photos"
            delete
                .click
                .sink {
                    let items = selected.value
                    guard !items.isEmpty else { return }
                    
                    let alert = NSAlert()
                    alert.alertStyle = .warning
                    alert.icon = .init(systemSymbolName: "trash", accessibilityDescription: nil)
                    alert.messageText = items.count == 1 ? "Delete photo?" : "Delete photos?"
                    
                    let delete = alert.addButton(withTitle: "Delete")
                    let cancel = alert.addButton(withTitle: "Cancel")
                    delete.keyEquivalent = "\r"
                    cancel.keyEquivalent = "\u{1b}"
                    if alert.runModal().rawValue == delete.tag {
                        selected.send([])
                        info.value = info
                            .value
                            .filter {
                                !items.contains($0.picture)
                            }
                        
                        items
                            .forEach {
                                try? FileManager.default.trashItem(at: $0.id, resultingItemURL: nil)
                            }
                        
                        Task {
                            await UNUserNotificationCenter.send(message: items.count == 1 ? "Delete photo!" : "Deleted photos!")
                        }
                    }
                }
                .store(in: &subs)
            
            let export = Option(icon: "square.and.arrow.up", size: 13)
            export.toolTip = "Export"
            
            let left = NSStackView(views: [title, sorting, zooming])
            left.translatesAutoresizingMaskIntoConstraints = false
            left.spacing = 16
            addSubview(left)
            
            let right = NSStackView(views: [delete, export])
            right.translatesAutoresizingMaskIntoConstraints = false
            addSubview(right)
            
            left.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
            left.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            
            right.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
            right.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            
            info
                .map {
                    $0.count
                }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { count in
                    title.attributedStringValue = .make {
                        $0.append(.make(url.lastPathComponent, attributes: [
                            .font: NSFont.preferredFont(forTextStyle: .body),
                            .foregroundColor: NSColor.labelColor]))
                        
                        if count > 0 {
                            $0.newLine()
                            $0.append(.make(count.formatted(), attributes: [
                                .font: NSFont.monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .light),
                                .foregroundColor: NSColor.secondaryLabelColor]))
                            $0.append(.make(count == 1 ? " photo" : " photos", attributes: [
                                .font: NSFont.systemFont(ofSize: NSFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .light),
                                .foregroundColor: NSColor.secondaryLabelColor]))
                        }
                    }
                }
                .store(in: &subs)
            
            zoom
                .sink {
                    zooming.selectedSegment = $0.rawValue
                }
                .store(in: &subs)
            
            selected
                .map {
                    $0.isEmpty
                }
                .removeDuplicates()
                .sink {
                    delete.state = $0 ? .hidden : .on
                    export.state = $0 ? .hidden : .on
                }
                .store(in: &subs)
        }
    
    @objc private func change(_ segemented: NSSegmentedControl) {
        zoom.send(.init(rawValue: segemented.selectedSegment)!)
    }
}
