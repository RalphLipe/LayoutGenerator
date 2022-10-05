//
//  LayoutGenerator.swift
//  LayoutGenerator
//
//  Created by Ralph Lipe on 5/14/22.
//

import Foundation
import ContractBridge




class LayoutGenerator {

    
    public static func generateLayouts() -> Set<RankPositionsId> {
        var result = Set<RankPositionsId>()
        let end = UInt64(pow(3.0, 13.0))
        var x = UInt64(pow(3.0, 8.0)) + 1   // Start with at least a 10 in one position
        while x < end {
            var layout = RankPositions()
            var y = x
            var lowN = 0
            var lowS = 0
            for _ in Rank.two...Rank.seven {
                let pos = y % 3
                if pos == 1 {
                    lowN += 1
                } else if pos == 2 {
                    lowS += 1
                }
                y /= 3
            }
            var lowRank = Rank.two
            while lowS > 0 {
                layout[lowRank] = .south
                lowRank = lowRank.nextHigher!
                lowS -= 1
            }
            while lowN > 0 {
                layout[lowRank] = .north
                lowRank = lowRank.nextHigher!
                lowN -= 1
            }
            for rank in Rank.eight...Rank.ace {
                let pos = y % 3
                if pos > 0 {
                    layout[rank] = pos == 1 ? .south : .north
                }
                y /= 3
            }
            layout.reassignRanks(from: nil, to: .east)
            let nCount = layout.count(for: .north)
            let sCount = layout.count(for: .south)
            layout = layout.normalized()
            if Self.isInteresting(layout: layout, nCount: nCount, sCount: sCount) {
                // Now if the layout is 3-3 or 4-4 or 5-5 make sure that north has the high cards
                if nCount == sCount {
                    let nRanks = layout[.north]
                    let sRanks = layout[.south]
                    if sRanks.max()! > nRanks.max()! {
                        layout[.north] = sRanks
                        layout[.south] = nRanks
                    }
                }

                layout.reassignRanks(from: .east, to: nil)
                if result.insert(layout.id).inserted {
                    print("\(layout)")
                }
            }
            x += 1
        }
        return result
    }


    private static func isInteresting(layout: RankPositions, nCount: Int, sCount: Int) -> Bool {
        if nCount < 3 { return false }
        if sCount == 0 { return false }
        if nCount < sCount { return false }
        
        if nCount + sCount > 11 { return false }
        // All winners in the south is very uninteresting
        let sChoices = layout.playableRanges(for: .south)
        if sChoices.count == 1 && sChoices.first!.upperBound == .ace { return false }
        var remainingCards = min(nCount, 13 - nCount - sCount)
        var rank = layout[.ace] == .east ? Rank.king : Rank.ace     // TODO: This assumes E holds all cards
        while remainingCards > 1 && (layout[rank] == .north || layout[rank] == .south) {
            remainingCards -= 1
            rank = rank.nextLower!
        }
        if remainingCards <= 1 { return false }
    
        return true
    }
        /*
        // We know that nCount >= sCount so use it for long analysis
        assert(layout.count(for: .north) > 0 && layout.count(for: .south) > 0)
        let nChoices = layout.playableRanges(for: .north)
        let sChoices = layout.playableRanges(for: .south)
        // Only winners and losers is trivial
        if nChoices.mid == nil && sChoices.mid == nil { return false }
        // If both north and south have only one range of cards to play this is boring
        if nChoices.all.count == 1 && sChoices.all.count == 1 { return false }
        
        // If south has only one choice, and that choice is the same range as north's highest
        // choice then drop this one.  If south's range is greater than the highest north range
        // then that is not interesting either.
        if sChoices.count == 1 && sChoices.all[0].range.lowerBound >= nChoices.last!.range.lowerBound { return false }
        
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
    
    private func distributeHighCards(rank: Rank?, results: inout Set<RankPositionsId>) {
        if let rank = rank {
            for position in [Position.north, Position.south] {
                layout[rank] = position
                distributeHighCards(rank: rank.nextHigher, results: &results)
            }
            layout[rank] = nil
            distributeHighCards(rank: rank.nextHigher, results: &results)
        } else {
            // A layout is only interesting if:
            // North has >= cards in south
            // North/South can not trivially win all tricks
            // East/West can not trivially win all tricks
            if isIntersetingLayout() {
                results.insert(layout.normalized().id)
            }
        }
    }
    
    private func distributeLowCards(position: Position?, startRank: Rank, results: inout Set<RankPositionsId>, endRank: Rank = Rank.eight) {
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
        var results: Set<RankPositionsId> = []
        LayoutGenerator().distributeLowCards(position: .north, startRank: Rank.two, results: &results)
        
        // TODO:  Should I move this somewhere in a class member?
        for id in results {
            var layout = RankPositions(id: id)
            if layout.count(for: .north) == layout.count(for: .south) {
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
     */
}
