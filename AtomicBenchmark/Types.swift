//
//  Executer.swift
//  AtomicBenchmark
//
//  Created by Vadym Bulavin on 6/29/18.
//  Copyright © 2018 Vadim Bulavin. All rights reserved.
//

import Cocoa

struct Measurement {
	let iterations: Int
	let duration: TimeInterval
	let operation: String

    static func +=(_ lhs: inout Measurement,_ rhs: Measurement) {
        guard lhs.iterations == rhs.iterations, lhs.operation == rhs.operation else {
            fatalError("Incorrect usage")
        }
        lhs = Measurement(iterations: lhs.iterations, duration: lhs.duration + rhs.duration, operation: lhs.operation)
    }

    static func /(_ lhs: Measurement, _ rhs: TimeInterval) -> Measurement {
        return Measurement(iterations: lhs.iterations, duration: lhs.duration / rhs, operation: lhs.operation)
    }
}

struct Result {
	let measurements: [Measurement]
	let title: String
}

struct Report {
	var results: [Result]

	mutating func add(measurements: [Measurement], title: String) {
		let result = Result(measurements: measurements, title: title)
		results.append(result)
	}
}
