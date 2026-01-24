
// FBLA/UI/InfinitePager.swift
// Swift 6 • iOS 17+
//
///  A horizontally scrolling, wrap-around pager built on `UIPageViewController`.
///
///  - Uses a view builder closure that inherits the SwiftUI environment.
///  - Emits continuous scroll progress in `[-1, +1]`.
///  - Caches controllers for efficiency and sets transparent backgrounds.
///
import SwiftUI
import UIKit

/// A horizontally scrolling, infinite, wrap-around pager.
struct InfinitePager<Content: View>: UIViewControllerRepresentable {
    /// The bound index of the visible page.
    @Binding var index: Int
    /// Total number of pages.
    let count: Int
    /// Builder for a given page index.
    @ViewBuilder let builder: (Int) -> Content
    /// Live scroll progress callback, clamped to `[-1, +1]`.
    var onScrollProgress: ((Double) -> Void)? = nil

    /// Coordinator object that acts as the page data source, delegate, and scroll listener.
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    /// Creates and configures the underlying `UIPageViewController`.
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pvc.dataSource = context.coordinator
        pvc.delegate = context.coordinator
        pvc.view.backgroundColor = .clear
        pvc.view.isOpaque = false
        context.coordinator.attachScrollListener(in: pvc)
        pvc.setViewControllers([context.coordinator.controller(at: safeIndex(index))], direction: .forward, animated: false)
        return pvc
    }

    /// Updates the `UIPageViewController` to the target index via the shortest direction.
    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {
        guard let current = pvc.viewControllers?.first,
              let curIdx = context.coordinator.index(of: current)
        else { return }
        let tgt = safeIndex(index)
        guard curIdx != tgt else { return }
        let n = count
        let forward = (tgt - curIdx + n) % n
        let reverse = (curIdx - tgt + n) % n
        let dir: UIPageViewController.NavigationDirection = forward <= reverse ? .forward : .reverse
        pvc.setViewControllers([context.coordinator.controller(at: tgt)], direction: dir, animated: true)
    }

    /// Wraps any integer index safely into the `[0, count)` range.
    private func safeIndex(_ i: Int) -> Int { (i % count + count) % count }

    // MARK: Coordinator

    /// The pager coordinator handling data source, delegate, and scroll progress.
    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {
        let parent: InfinitePager
        private var cache: [Int: UIViewController] = [:]
        private weak var scrollView: UIScrollView?
        private var lastProgress: Double = 0

        init(_ parent: InfinitePager) { self.parent = parent }

        /// Returns a hosting controller for a page index, caching the instance.
        func controller(at i: Int) -> UIViewController {
            if let cached = cache[i] { return cached }
            let view = AnyView(parent.builder(i))
            let vc = UIHostingController(rootView: view)
            vc.view.backgroundColor = .clear
            vc.view.isOpaque = false
            cache[i] = vc
            return vc
        }

        /// Finds the index corresponding to a given controller, if cached.
        func index(of controller: UIViewController) -> Int? {
            cache.first(where: { $0.value === controller })?.key
        }

        /// Installs a scroll listener on the embedded `UIScrollView`.
        func attachScrollListener(in pvc: UIPageViewController) {
            pvc.view.subviews.forEach { $0.backgroundColor = .clear; $0.isOpaque = false }
            if let sv = pvc.view.subviews.compactMap({ $0 as? UIScrollView }).first {
                scrollView = sv
                sv.delegate = self
                sv.backgroundColor = .clear
                sv.isOpaque = false
            }
        }

        /// Reports continuous scroll progress in `[-1, +1]` with light throttling.
        func scrollViewDidScroll(_ sv: UIScrollView) {
            guard sv.bounds.width > 0 else { return }
            let raw = (sv.contentOffset.x - sv.bounds.width) / sv.bounds.width
            let clamped = max(-1.0, min(1.0, Double(raw)))
            guard abs(clamped - lastProgress) > 0.0005 else { return }
            lastProgress = clamped
            parent.onScrollProgress?(clamped)
        }

        /// Updates the bound page index on completed transitions and snaps progress to 0.
        func pageViewController(_ pvc: UIPageViewController, didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed, let current = pvc.viewControllers?.first, let curIdx = index(of: current) {
                parent.index = curIdx
            }
            parent.onScrollProgress?(0)
        }

        // Wrap-around data source
        func pageViewController(_ pvc: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? {
            guard parent.count > 0, let curIdx = index(of: vc) else { return nil }
            let prev = (curIdx - 1 + parent.count) % parent.count
            return controller(at: prev)
        }

        func pageViewController(_ pvc: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? {
            guard parent.count > 0, let curIdx = index(of: vc) else { return nil }
            let next = (curIdx + 1) % parent.count
            return controller(at: next)
        }
    }
}
