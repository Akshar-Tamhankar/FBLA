
// UI/InfinitePager.swift
import SwiftUI
import UIKit

/// Minimal infinite pager using UIPageViewController with wrap-around.
/// - Efficient: keeps stable controllers and no selection resets.
/// - Index binding is 0..<controllers.count; swipes update it automatically.
struct InfinitePager: UIViewControllerRepresentable {
    let controllers: [UIViewController]
    @Binding var index: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pvc.dataSource = context.coordinator
        pvc.delegate   = context.coordinator
        let initial = controllers[safe: index] ?? controllers.first!
        pvc.setViewControllers([initial], direction: .forward, animated: false)
        return pvc
    }

    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {
        guard let current = pvc.viewControllers?.first,
              let target = controllers[safe: index],
              current !== target else { return }

        // Choose direction based on proximity for nicer animated jumps (e.g., pill taps).
        if let curIdx = controllers.firstIndex(where: { $0 === current }),
           let tgtIdx = controllers.firstIndex(where: { $0 === target }) {
            let n = controllers.count
            let forward = (tgtIdx - curIdx + n) % n
            let reverse = (curIdx - tgtIdx + n) % n
            pvc.setViewControllers([target], direction: forward <= reverse ? .forward : .reverse, animated: true)
        } else {
            pvc.setViewControllers([target], direction: .forward, animated: true)
        }
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: InfinitePager
        init(_ parent: InfinitePager) { self.parent = parent }

        // Wrap-around: previous of first is last
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let idx = parent.controllers.firstIndex(where: { $0 === viewController }) else { return nil }
            let prev = (idx - 1 + parent.controllers.count) % parent.controllers.count
            return parent.controllers[prev]
        }

        // Wrap-around: next of last is first
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let idx = parent.controllers.firstIndex(where: { $0 === viewController }) else { return nil }
            let next = (idx + 1) % parent.controllers.count
            return parent.controllers[next]
        }

        // Update bound index after the interactive swipe completes.
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed,
                  let current = pageViewController.viewControllers?.first,
                  let idx = parent.controllers.firstIndex(where: { $0 === current }) else { return }
            parent.index = idx
        }
    }
}

private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
