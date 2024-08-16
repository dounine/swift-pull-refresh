//
//  ContentView.swift
//  SwiftPullRefresh
//
//  Created by lake on 2024/8/16.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            LazyVStack(spacing: 0) {
                ForEach(0 ..< 30, id: \.self) { item in
                    Divider()
                    Rectangle()
                        .frame(height: 50)
                        .opacity(0.9 - Double(item)*0.03)
                        .overlay {
                            Text("\(item)")
                                .foregroundStyle(.white)
                        }
                }
            }
            .onRefresh {
                try? await Task.sleep(nanoseconds: 1000*1000*1000*3)
                print("刷新")
            }
            .navigationTitle("下拉刷新")
        }
    }
}

public struct ScrollDetector: UIViewRepresentable {
    public var onRefresh: () async -> Void

    public init(
        onRefresh: @escaping () async -> Void = {}
    ) {
        self.onRefresh = onRefresh
    }

    public class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: ScrollDetector
        var uiView: UIScrollView? = nil
        init(parent: ScrollDetector) {
            self.parent = parent
        }

        public func scrollViewDidScroll(_ scrollView: UIScrollView) {}

        public func scrollViewWillEndDragging(
            _: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {}

        public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}

        @objc func handleRefresh() {
            Task {
                await parent.onRefresh()
                refreshControl?.endRefreshing()
            }
        }

        var isDelegateAdded: Bool = false
        var refreshControl: UIRefreshControl?
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    public func makeUIView(context _: Context) -> UIView {
        return UIView()
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let scrollview = uiView.superview?.superview?.superview as? UIScrollView, !context.coordinator.isDelegateAdded {
                /// Adding Delegate
                scrollview.delegate = context.coordinator
                context.coordinator.isDelegateAdded = true
                /// Adding refresh control
                let refreshControl = UIRefreshControl()
                refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh), for: .valueChanged)
                scrollview.refreshControl = refreshControl
                context.coordinator.refreshControl = refreshControl
            }
        }
    }
}

struct ScrollViewModifier: ViewModifier {
    let onRefresh: () async -> Void
    func body(content: Content) -> some View {
        ScrollView {
            content
                .background(ScrollDetector(onRefresh: onRefresh))
        }
    }
}

extension View {
    func onRefresh(refresh: @escaping () async -> Void) -> some View {
        modifier(ScrollViewModifier(onRefresh: refresh))
    }
}

#Preview {
    ContentView()
}
