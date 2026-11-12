import SwiftUI
import StudyNookCore

/// The black island at the notch: collapsed (wings around the notch) ↔ expanded (scene + timer).
struct NotchRootView: View {
    let engine: PomodoroEngine
    let model: NotchViewModel

    var body: some View {
        let expanded = model.isExpanded
        let active = engine.phase != .idle
        let size = expanded ? model.expandedSize : model.collapsedSize(active: active)
        let shape = NotchShape(
            topRadius: expanded ? NotchLayout.expandedTopRadius : NotchLayout.collapsedTopRadius,
            bottomRadius: expanded ? NotchLayout.expandedBottomRadius : NotchLayout.collapsedBottomRadius
        )

        ZStack(alignment: .top) {
            shape
                .fill(.black)
                .shadow(color: .black.opacity(expanded ? 0.45 : 0), radius: expanded ? 16 : 0, y: 6)

            Group {
                if expanded {
                    ExpandedContent(engine: engine, model: model)
                        .transition(.blurReplace.combined(with: .opacity))
                } else if active {
                    CompactContent(engine: engine, model: model)
                        .transition(.blurReplace.combined(with: .opacity))
                }
            }
            .frame(width: size.width, height: size.height, alignment: .top)
            .clipShape(shape)
        }
        .frame(width: size.width, height: size.height)
        // In idle the collapsed island matches the notch exactly, so it is hidden.
        .opacity(!expanded && !active ? 0 : 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .animation(NotchLayout.spring, value: expanded)
        .animation(NotchLayout.spring, value: active)
        .preferredColorScheme(.dark)
    }
}
