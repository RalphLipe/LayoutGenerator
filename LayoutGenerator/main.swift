//
//  main.swift
//  LayoutGenerator
//
//  Created by Ralph Lipe on 5/14/22.
//

import Foundation
import ContractBridge

var layoutIds = LayoutGenerator.generateLayouts()
/*
for id in layoutIds {
    let layout = SuitLayout(suitLayoutId: id)
    print(layout.description)
}
*/
print("Total layouts = \(layoutIds.count)")


let originalCount = layoutIds.count
print("NOW PRUNING")
for id in layoutIds {
    let layout = SuitLayout(suitLayoutId: id)
    print("\(layout)", terminator: "")
    let analysis = CardCombinationAnalyzer.analyze(suitHolding: SuitHolding(suitLayout: layout))
    let bestLeads = analysis.bestLeads()
    if analysis.maxTricksAllLayouts == analysis.worstCaseTricks {
        print(" - No better than worst case no matter what...  Removed")
        layoutIds.remove(id)
    } else if bestLeads.first!.combinationsFor(desiredTricks: analysis.maxTricksAllLayouts) == analysis.totalCombinations {
        print(" - REMOVED - always makes \(analysis.maxTricksAllLayouts)")
        layoutIds.remove(id)
    } else if bestLeads.count == analysis.leads.count {
        print(" - TRIVIAL - all leads make the same tricks!")
        layoutIds.remove(id)
    } else {
        let maxTricks = bestLeads.first!.maxTricksAnyLayout
        let percent = bestLeads.first!.percentageFor(desiredTricks: maxTricks)
        if percent < 1.0 && maxTricks == analysis.worstCaseTricks + 1 {
            print(" - Some random drop of \(percent)% gets one trick!  Removed")
            layoutIds.remove(id)
        } else {
            print(" - Makes \(maxTricks) \(percent)% of the time")
        }
    }
}
print("After pruning, \(layoutIds.count) reamain of \(originalCount)")

var encoder = JSONEncoder()
let data = try! encoder.encode(layoutIds)
let s = String(data: data, encoding: .utf8)
print(s!)
var recovered: [Int] = []
let decoder = JSONDecoder()
let decodedIDs = try! decoder.decode(Array<Int>.self, from: data)
print(decodedIDs.count)
print(layoutIds.count)

