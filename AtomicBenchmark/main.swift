//
//  main.swift
//  AtomicBenchmark
//
//  Created by Vadym Bulavin on 6/29/18.
//  Copyright © 2018 Vadim Bulavin. All rights reserved.
//

import Foundation

let lock = NSLock()
let nsLockSample = LockSample(title: "Lock", lock: lock.lock, unlock: lock.unlock)

let mutex = Mutex()
let mutexSample = LockSample(title: "Mutex", lock: mutex.lock, unlock: mutex.unlock)

let spinLock = SpinLock()
let spinLockSample = LockSample(title: "Spin Lock", lock: spinLock.lock, unlock: spinLock.unlock)

let rwLock = ReadWriteLock()
let rwLockSample = RWLockSample(title: "Read Write Lock", setterLock: rwLock.writerLock, getterLock: rwLock.readerLock, unlock: rwLock.unlock)

let dispatchQueueSample = DispatchQueueSample()

let operationsQueueSample = OperationsQueueSample()

let samples: [Sample] = [
    nsLockSample,
    mutexSample,
    spinLockSample,
	rwLockSample,
	dispatchQueueSample,
//    operationsQueueSample
]

let iterations =  [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16_384, 32_768, 65_536, 131_072, 262_144, 524_288]
let executer = GetterSetterBenchmark(settings: .init(numGetterThreads: 4,
                                                     numSetterThreads: 1,
                                                     attemptsPerIteration: 100,
                                                     iterationsPerSample: iterations,
                                                     getter_divide_setter: 32))

let results = samples.map(executer.measure)
let report = Report(results: results)
ReportRenderer(report: report).render()
CSVReportRenderer(report: report, fileName: "Benchmark.csv").render()
