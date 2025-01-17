//
//  Samples.swift
//  AtomicBenchmark
//
//  Created by Vadym Bulavin on 6/29/18.
//  Copyright © 2018 Vadim Bulavin. All rights reserved.
//

import Foundation

protocol Sample {
	var foo: Int { get set }
	var title: String { get }
}

class LockSample: Sample {
	private let lock: () -> Void
	private let unlock: () -> Void
	let title: String

	init(title: String, lock: @escaping () -> Void, unlock: @escaping () -> Void) {
		self.lock = lock
		self.unlock = unlock
		self.title = title
	}

	private var underlyingFoo = 0

	var foo: Int {
		get {
			lock()
			let value = underlyingFoo
			unlock()
			return value
		}
		set {
			lock()
			underlyingFoo = newValue
			unlock()
		}
	}
}

class RWLockSample: Sample {
    private let setterlock: () -> Void
    private let getterlock: (() -> Void)!
    private let unlock: () -> Void
    let title: String

    init(title: String, setterLock: @escaping () -> Void, getterLock: @escaping () -> Void, unlock: @escaping () -> Void) {
        self.setterlock = setterLock
        self.getterlock = getterLock
        self.unlock = unlock
        self.title = title
    }

    private var underlyingFoo = 0

    var foo: Int {
        get {
            getterlock()
            let value = underlyingFoo
            unlock()
            return value
        }
        set {
            setterlock()
            underlyingFoo = newValue
            unlock()
        }
    }
}

class DispatchQueueSample {
	private let queue = DispatchQueue(label: "com.vadimbulavin.DispatchQueueSample", qos: .userInteractive, attributes: .concurrent)
	private var underlyingFoo = 0

	var foo: Int {
		get {
			return queue.sync { underlyingFoo }
		}
		set {
            queue.sync(flags: .barrier) {
				self.underlyingFoo = newValue
			}
		}
	}
}

extension DispatchQueueSample: Sample {
	var title: String {
		return "Dispatch Queue"
	}
}

class OperationsQueueSample {
	private let queue: OperationQueue = {
		var q = OperationQueue()
		q.maxConcurrentOperationCount = 1
		return q
	}()
	private var underlyingFoo = 0

	var foo: Int {
		get {
			var foo: Int!
			execute(on: queue) { [underlyingFoo] in
				foo = underlyingFoo
			}
			return foo
		}
		set {
			execute(on: queue) {
				self.underlyingFoo = newValue
			}
		}
	}

	private func execute(on q: OperationQueue, block: @escaping () -> Void) {
		let op = BlockOperation(block: block)
		q.addOperation(op)
		op.waitUntilFinished()
	}
}

extension OperationsQueueSample: Sample {
	var title: String {
		return "Operations Queue"
	}
}
