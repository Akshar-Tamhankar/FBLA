
// UI/InfinitePager.swift
import SwiftUI
import UIKit

/// Infinite, wrap-around pager using UIPageViewController
/// - Builds pages via a closure so it inherits SwiftUI environment.
/// - Emits live swipe progress in [-1, +1] through `onScrollProgress`.
struct InfinitePager<Content: View>: UIViewControllerRepresentable {
    @Binding var index: Int
    let count: Int
    @ViewBuilder let builder: (Int) -> Content
    var onScrollProgress: ((Double) -> Void)? = nil   // live progress

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(transitionStyle: .scroll,
                                       navigationOrientation: .horizontal)

        // ✨ Make the pager itself transparent
        pvc.view.backgroundColor = .clear
        pvc.view.isOpaque = false

        pvc.dataSource = context.coordinator
        pvc.delegate   = context.coordinator

        // Attach scroll delegate & clear backgrounds inside
        context.coordinator.attachScrollObserver(in: pvc)

        // Initial page
        let initial = context.coordinator.controller(at: safeIndex(index))
        pvc.setViewControllers([initial], direction: .forward, animated: false)
        return pvc
    }

    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {
        guard let current = pvc.viewControllers?.first,
              let curIdx   = context.coordinator.index(of: current) else { return }
        let tgtIdx = safeIndex(index)
        guard curIdx != tgtIdx else { return }

        let target = context.coordinator.controller(at: tgtIdx)
        let n = count
        let forward = (tgtIdx - curIdx + n) % n
        let reverse = (curIdx - tgtIdx + n) % n
        pvc.setViewControllers([target],
                               direction: forward <= reverse ? .forward : .reverse,
                               animated: true)
    }

    private func safeIndex(_ i: Int) -> Int { (i % count + count) % count }

    // MARK: - Coordinator
    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {
        let parent: InfinitePager
        private var cache: [Int: UIViewController] = [:]
        private weak var scrollView: UIScrollView?
        private var lastProgress: Double = 0

        init(_ parent: InfinitePager) { self.parent = parent }

        // Build or reuse a controller for a given index
        func controller(at i: Int) -> UIViewController {
            if let vc = cache[i] { return vc }
            let view = AnyView(parent.builder(i))               // allow mixed SwiftUI views
            let vc = UIHostingController(rootView: view)

            // ✨ Make each hosted page fully transparent
            vc.view.backgroundColor = .clear
            vc.view.isOpaque = false

            cache[i] = vc
            return vc
        }

        func index(of controller: UIViewController) -> Int? {
            cache.first(where: { $0.value === controller })?.key
        }

        // Attach to internal scroll view so we can report progress
        func attachScrollObserver(in pvc: UIPageViewController) {
            // Clear the UIPageViewController’s internal hierarchy backgrounds
            pvc.view.subviews.forEach { sub in
                sub.backgroundColor = .clear
                sub.isOpaque = false
            }

            if let sv = pvc.view.subviews.compactMap({ $0 as? UIScrollView }).first {
                sv.delegate = self
                sv.backgroundColor = .clear
                sv.isOpaque = false
                scrollView = sv
            }
        }

        // Emit continuous progress as user drags
        func scrollViewDidScroll(_ sv: UIScrollView) {
            guard sv.bounds.width > 0 else { return }
            // In UIPageViewController, contentOffset.x == width when centered on current page.
            let width = sv.bounds.width
            let raw = (sv.contentOffset.x - width) / width
            let clamped = max(-1.0, min(1.0, Double(raw)))
            guard abs(clamped - lastProgress) > 0.0005 else { return }
            lastProgress = clamped
            parent.onScrollProgress?(clamped)
        }

        func pageViewController(_ pvc: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            if completed,
               let current = pvc.viewControllers?.first,
               let curIdx  = index(of: current) {
                parent.index = curIdx
            }
            parent.onScrollProgress?(0) // snap
        }

        // Wrap-around
        func pageViewController(_ pvc: UIPageViewController,
                                viewControllerBefore vc: UIViewController) -> UIViewController? {
            guard parent.count > 0, let curIdx = index(of: vc) else { return nil }
            let prev = (curIdx - 1 + parent.count) % parent.count
            return controller(at: prev)
        }

        func pageViewController(_ pvc: UIPageViewController,
                                viewControllerAfter vc: UIViewController) -> UIViewController? {
            guard parent.count > 0, let curIdx = index(of: vc) else { return nil }
            let next = (curIdx + 1) % parent.count
            return controller(at: next)
        }
    }
}
