import AppKit
import Combine
import Core

final class Subbar: NSView {
    private var subs = Set<AnyCancellable>()
    
    required init?(coder: NSCoder) { nil }
    init(selected: CurrentValueSubject<[Core.Picture], Never>) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        
        selected
            .removeDuplicates()
            .sink { [weak self] selected in
                
            }
            .store(in: &subs)
    }
}
