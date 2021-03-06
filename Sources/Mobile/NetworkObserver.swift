//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch
import UIKit

protocol NetworkActivityIndicatorProtocol {
    var networkActivityIndicatorVisible: Bool { get set }
}

extension UIApplication: NetworkActivityIndicatorProtocol { }

class NetworkActivityController {

    static let shared = NetworkActivityController()

    let interval: TimeInterval
    private(set) var indicator: NetworkActivityIndicatorProtocol

    private var count = 0
    private var delayedHide: DispatchWorkItem?

    private let queue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.NetworkActivityController", qos: .userInteractive)

    init(timerInterval: TimeInterval = 1.0, indicator: NetworkActivityIndicatorProtocol = UIApplication.shared) {
        self.interval = timerInterval
        self.indicator = indicator
    }

    /// start() is thread-safe
    func start() {
        queue.async {
            self.count += 1
            self.update()
        }
    }

    /// stop() is thread-safe
    func stop() {
        queue.async {
            self.count -= 1
            self.update()
        }
    }

    private func update() {
        if count > 0 {
            updateIndicator(withVisibility: true)
        }
        else if count == 0 {
            let workItem = DispatchWorkItem(block: {
                self.updateIndicator(withVisibility: false)
            })
            delayedHide = workItem
            queue.asyncAfter(deadline: .now() + interval, execute: workItem)
        }
    }

    private func updateIndicator(withVisibility visibility: Bool) {
        delayedHide?.cancel()
        delayedHide = nil
        DispatchQueue.main.async {
            // only set the visibility if it has changed
            if self.indicator.networkActivityIndicatorVisible != visibility {
                self.indicator.networkActivityIndicatorVisible = visibility
            }
        }
    }
}

public class NetworkObserver: ProcedureObserver {

    private let networkActivityController: NetworkActivityController

    init(controller: NetworkActivityController) {
        networkActivityController = controller
    }

    public convenience init() {
        self.init(controller: NetworkActivityController.shared)
    }

    public func will(execute procedure: Procedure) {
        networkActivityController.start()
    }

    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        networkActivityController.stop()
    }
}
