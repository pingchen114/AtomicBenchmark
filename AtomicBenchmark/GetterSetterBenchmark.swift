//
//  GetterSetterBenchmark.swift
//  AtomicBenchmark
//
//  Created by Vadym Bulavin on 6/29/18.
//  Copyright © 2018 Vadim Bulavin. All rights reserved.
//

import Foundation

struct GetterSetterBenchmark {
    enum OperationName: String {
        case getter = "Getter"
        case setter = "Setter"
    }
	struct Settings {
        let numGetterThreads: Int
        let numSetterThreads: Int
		let attemptsPerIteration: Int
		let iterationsPerSample: [Int]
        let getter_divide_setter: Int
	}

	let settings: Settings

	func measure(sample: Sample) -> Result {
        print("Start \(sample.title)")

        var sample = sample
        let workQueue = DispatchQueue(label: "measure-queue", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        let group = DispatchGroup()
        var getterMeasurements: [Measurement] = []
        var setterMeasurements: [Measurement] = []

        self.settings.iterationsPerSample.forEach { iterations in

            if settings.numGetterThreads > 0 {
                group.enter()
                workQueue.async() {
                    let getterMeasure = self.makeMeasurement(operation: .getter, numberOfIterations: iterations) { _ in
                        let _ = sample.foo
                    }
                    getterMeasurements.append(getterMeasure)
                    group.leave()
                }
            }

            if settings.numSetterThreads > 0 {
                group.enter()
                workQueue.async {
                    let setterMeasure = self.makeMeasurement(operation: .setter, numberOfIterations: iterations) {
                        sample.foo = $0
                    }
                    setterMeasurements.append(setterMeasure)
                    group.leave()
                }
            }


            group.wait()
        }

        return Result(measurements: getterMeasurements + setterMeasurements, title: sample.title)
	}

    private func makeMeasurement(operation: OperationName, numberOfIterations: Int, block: @escaping (Int) -> Void) -> Measurement {
        let duration = averageBenchmark(operation: operation, iterations: numberOfIterations, numberOfAttempts: settings.attemptsPerIteration, block: block)
		return Measurement(iterations: numberOfIterations, duration: duration, operation: operation.rawValue)
	}

	private func benchmark(block: () -> Void) -> TimeInterval {
		let startTime = CFAbsoluteTimeGetCurrent()
		block()
		let endTime = CFAbsoluteTimeGetCurrent()
		let totalTime = endTime - startTime
		return totalTime
	}

    private func averageBenchmark(operation: OperationName, iterations: Int, numberOfAttempts: Int, block: @escaping (Int) -> Void) -> TimeInterval {
		var accumulatedResult: TimeInterval = 0
        let lock = SpinLock()
        let workingGroup = DispatchGroup()
        let getterQueue = DispatchQueue(label: "Getter Queue", qos: .userInteractive, attributes: .concurrent)
        let setterQueue = DispatchQueue(label: "Setter Queue", qos: .userInteractive, attributes: .concurrent)

		for _ in 0..<numberOfAttempts {
            switch operation {
            case .getter:
                for _ in 0..<settings.numGetterThreads {
                    workingGroup.enter()
                    getterQueue.async {
                        let iterations = max(1, iterations / self.settings.numGetterThreads)
                        let result = self.benchmark {
                            for i in 0..<iterations {
                                block(i)
                            }
                        }

                        lock.lock()
                        accumulatedResult += result
                        lock.unlock()
                        workingGroup.leave()
                    }
                }
            case .setter:
                for _ in 0..<settings.numSetterThreads {
                    workingGroup.enter()
                    setterQueue.async {
                        let iterations = max(1, iterations / (self.settings.numSetterThreads * self.settings.getter_divide_setter))
                        let result = self.benchmark {
                            for i in 0..<iterations {
                                block(i)
                            }
                        }

                        lock.lock()
                        accumulatedResult += result
                        lock.unlock()
                        workingGroup.leave()
                    }
                }
            }
            workingGroup.wait()
		}

        switch operation {
        case .getter:
            return accumulatedResult / TimeInterval(numberOfAttempts * settings.numGetterThreads)
        case .setter:
            return accumulatedResult / TimeInterval(numberOfAttempts * settings.numSetterThreads * settings.getter_divide_setter)
        }
	}

}


