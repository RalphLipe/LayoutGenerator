//
//  LayoutGenerator.swift
//  LayoutGenerator
//
//  Created by Ralph Lipe on 5/14/22.
//

import Foundation
import ContractBridge




class LayoutGenerator {
    private var layout: SuitLayout
    
    private init() {
        layout = SuitLayout()
        layout.assignNilPositions(.north)
    }
    
    private func isIntersetingLayout() -> Bool {
        let nCount = layout.countFor(position: .north)
        if nCount < 3 { return false }
        let sCount = layout.countFor(position: .south)
        if nCount < sCount || sCount == 0 { return false }
        
        // We know that nCount >= sCount so use it for long analysis
        let suitHolding = SuitHolding(suitLayout: layout)
        assert(suitHolding[.north].count > 0 && suitHolding[.south].count > 0)
        let nChoices = suitHolding.choices(.north)
        let sChoices = suitHolding.choices(.south)
        // Only winners and losers is trivial
        if nChoices.mid == nil && sChoices.mid == nil { return false }
        // If both north and south have only one range of cards to play this is boring
        if nChoices.all.count == 1 && sChoices.all.count == 1 { return false }
        
        // If south has only one choice, and that choice is the same range as north's highest
        // choice then drop this one.  If south's range is greater than the highest north range
        // then that is not interesting either.
        if sChoices.all.count == 1 && sChoices.all[0].range.lowerBound >= nChoices.all.last!.range.lowerBound { return false }
        
        var nsWinners = 0
        if let sWin = sChoices.win {
            let sWinCount = sWin.count
            if sWinCount == sCount { return false }
            nsWinners += sWin.count
        }
        if let nWin = nChoices.win {
            nsWinners += nWin.count
        }
        if nsWinners >= nCount { return false }
        let remainingCount = Rank.allCases.count - nCount - sCount
        if nsWinners >= remainingCount { return false }
        let eChoices = suitHolding.choices(.east)
        if let eWin = eChoices.win {
            let eWinCount = eWin.count
            if eWinCount >= nCount { return false }
            // If north is all low and east's winners, no matter how distributed can squash all of
            // south's cards then this is uninteresting.  Assume E/W honors split, so divide by 2
            if nChoices.mid == nil && nChoices.win == nil && eWinCount / 2 >= sCount { return false }
        }
        return true
    }
    
    private func distributeHighCards(rank: Rank?, results: inout Set<SuitLayoutIdentifier>) {
        if let rank = rank {
            for position in [Position.north, Position.south, Position.east] {
                layout[rank] = position
                distributeHighCards(rank: rank.nextHigher, results: &results)
            }
        } else {
            // A layout is only interesting if:
            // North has >= cards in south
            // North/South can not trivially win all tricks
            // East/West can not trivially win all tricks
            if isIntersetingLayout() {
                var sortedLayout = layout
                sortedLayout.reassignRanks(random: false)
                results.insert(sortedLayout.id)
            }
        }
    }
    
    private func distributeLowCards(position: Position, startRank: Rank, results: inout Set<SuitLayoutIdentifier>, endRank: Rank = Rank.eight) {
        if startRank == endRank {
            distributeHighCards(rank: startRank, results: &results)
        } else {
            for rank in startRank..<endRank {
                layout[rank] = position
            }
            if position == .east {
                distributeHighCards(rank: endRank, results: &results)
            } else {
                var nextPosStart: Rank? = endRank
                let nextPosition = position == .north ? Position.south : .east
                while nextPosStart != nil && nextPosStart! >= startRank {
                    distributeLowCards(position: nextPosition, startRank: nextPosStart!, results: &results)
                    nextPosStart = nextPosStart?.nextLower
                }
            }
        }
       
    }
    
    
    public static func generateLayouts() -> Set<SuitLayoutIdentifier> {
        var results: Set<SuitLayoutIdentifier> = []
        LayoutGenerator().distributeLowCards(position: .north, startRank: Rank.two, results: &results)
        
        // TODO:  Should I move this somewhere in a class member?
        for id in results {
            var layout = SuitLayout(suitLayoutId: id)
            if layout.countFor(position: .north) == layout.countFor(position: .south) {
                for rank in Rank.allCases {
                    if layout[rank] == .north {
                        layout[rank] = .south
                    } else if layout[rank] == .south {
                        layout[rank] = .north
                    }
                }
                if results.contains(layout.id) {
                    print("removing \(id), same as \(layout.id)")
                    results.remove(id)
                }
            }
        }
        return results
    }
}
