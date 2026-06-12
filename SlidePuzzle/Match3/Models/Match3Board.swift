//
//  Match3Board.swift
//  SlidePuzzle
//
//  Pure-Swift match-3 game logic: board generation, swap validation,
//  match detection, gravity, refill, cascades and deadlock reshuffle.
//  No SpriteKit dependency — the scene replays the steps this produces.
//

import Foundation

struct GridPosition: Hashable {
    let col: Int
    let row: Int

    func isAdjacent(to other: GridPosition) -> Bool {
        abs(col - other.col) + abs(row - other.row) == 1
    }
}

/// One resolved round of the cascade loop, replayable by the scene.
struct CascadeStep {
    let matched: Set<GridPosition>
    let falls: [(from: GridPosition, to: GridPosition)]
    let spawns: [(at: GridPosition, type: TileType, dropFromRow: Int)]
    let scoreDelta: Int
    let multiplier: Int
}

enum SwapOutcome {
    case invalid
    case valid(steps: [CascadeStep])
    /// Valid move whose cascades left the board with no possible moves;
    /// `newLayout` is the reshuffled board to animate to.
    case validThenShuffle(steps: [CascadeStep], newLayout: [GridPosition: TileType])
}

final class Match3Board {

    let columns: Int
    let rows: Int

    // grid[col][row]; row 0 is the bottom.
    private var grid: [[TileType?]]

    init(columns: Int = 7, rows: Int = 7) {
        self.columns = columns
        self.rows = rows
        self.grid = Array(repeating: Array(repeating: nil, count: rows), count: columns)
        generateBoard()
    }

    // MARK: - Access

    func tile(at position: GridPosition) -> TileType? {
        guard contains(position) else { return nil }
        return grid[position.col][position.row]
    }

    func contains(_ position: GridPosition) -> Bool {
        position.col >= 0 && position.col < columns && position.row >= 0 && position.row < rows
    }

    // MARK: - Generation

    private func generateBoard() {
        repeat {
            for col in 0..<columns {
                for row in 0..<rows {
                    var excluded: Set<TileType> = []
                    // Avoid completing a horizontal run of 3 to the left.
                    if col >= 2,
                       let a = grid[col - 1][row], let b = grid[col - 2][row], a == b {
                        excluded.insert(a)
                    }
                    // Avoid completing a vertical run of 3 below.
                    if row >= 2,
                       let a = grid[col][row - 1], let b = grid[col][row - 2], a == b {
                        excluded.insert(a)
                    }
                    grid[col][row] = TileType.random(excluding: excluded)
                }
            }
        } while !hasPossibleMoves()
    }

    // MARK: - Swapping

    func attemptSwap(_ a: GridPosition, _ b: GridPosition) -> SwapOutcome {
        guard contains(a), contains(b), a.isAdjacent(to: b),
              grid[a.col][a.row] != nil, grid[b.col][b.row] != nil else {
            return .invalid
        }

        swapTiles(a, b)
        if findMatches().isEmpty {
            swapTiles(a, b) // revert
            return .invalid
        }

        let steps = resolveCascades()

        if hasPossibleMoves() {
            return .valid(steps: steps)
        }
        return .validThenShuffle(steps: steps, newLayout: reshuffle())
    }

    private func swapTiles(_ a: GridPosition, _ b: GridPosition) {
        let tmp = grid[a.col][a.row]
        grid[a.col][a.row] = grid[b.col][b.row]
        grid[b.col][b.row] = tmp
    }

    // MARK: - Match detection

    /// All positions that are part of a horizontal or vertical run of >= 3.
    func findMatches() -> Set<GridPosition> {
        var matched: Set<GridPosition> = []

        // Horizontal runs
        for row in 0..<rows {
            var runStart = 0
            for col in 1...columns {
                let continues = col < columns
                    && grid[col][row] != nil
                    && grid[col][row] == grid[runStart][row]
                if !continues {
                    if col - runStart >= 3, grid[runStart][row] != nil {
                        for c in runStart..<col {
                            matched.insert(GridPosition(col: c, row: row))
                        }
                    }
                    runStart = col
                }
            }
        }

        // Vertical runs
        for col in 0..<columns {
            var runStart = 0
            for row in 1...rows {
                let continues = row < rows
                    && grid[col][row] != nil
                    && grid[col][row] == grid[col][runStart]
                if !continues {
                    if row - runStart >= 3, grid[col][runStart] != nil {
                        for r in runStart..<row {
                            matched.insert(GridPosition(col: col, row: r))
                        }
                    }
                    runStart = row
                }
            }
        }

        return matched
    }

    // MARK: - Cascade resolution

    private func resolveCascades() -> [CascadeStep] {
        var steps: [CascadeStep] = []
        var multiplier = 1

        while true {
            let matched = findMatches()
            if matched.isEmpty { break }

            // Clear matched tiles.
            for position in matched {
                grid[position.col][position.row] = nil
            }

            // Gravity: compact each column downward.
            var falls: [(from: GridPosition, to: GridPosition)] = []
            for col in 0..<columns {
                var writeRow = 0
                for row in 0..<rows {
                    guard let tile = grid[col][row] else { continue }
                    if row != writeRow {
                        grid[col][writeRow] = tile
                        grid[col][row] = nil
                        falls.append((from: GridPosition(col: col, row: row),
                                      to: GridPosition(col: col, row: writeRow)))
                    }
                    writeRow += 1
                }
            }

            // Refill empty cells from the top; dropFromRow staggers spawn heights
            // so stacked spawns fall in order.
            var spawns: [(at: GridPosition, type: TileType, dropFromRow: Int)] = []
            for col in 0..<columns {
                var spawnOffset = 0
                for row in 0..<rows where grid[col][row] == nil {
                    let type = TileType.random()
                    grid[col][row] = type
                    spawns.append((at: GridPosition(col: col, row: row),
                                   type: type,
                                   dropFromRow: rows + spawnOffset))
                    spawnOffset += 1
                }
            }

            let scoreDelta = matched.count * 10 * multiplier
            steps.append(CascadeStep(matched: matched,
                                     falls: falls,
                                     spawns: spawns,
                                     scoreDelta: scoreDelta,
                                     multiplier: multiplier))
            multiplier += 1
        }

        return steps
    }

    // MARK: - Deadlock detection & reshuffle

    /// True if some adjacent swap would produce a match.
    func hasPossibleMoves() -> Bool {
        for col in 0..<columns {
            for row in 0..<rows {
                let here = GridPosition(col: col, row: row)
                for neighbor in [GridPosition(col: col + 1, row: row),
                                 GridPosition(col: col, row: row + 1)] where contains(neighbor) {
                    swapTiles(here, neighbor)
                    let creates = !findMatches().isEmpty
                    swapTiles(here, neighbor)
                    if creates { return true }
                }
            }
        }
        return false
    }

    /// Shuffle the existing tiles until the board has no immediate matches
    /// and at least one possible move. Returns the new layout.
    func reshuffle() -> [GridPosition: TileType] {
        var types: [TileType] = []
        for col in 0..<columns {
            for row in 0..<rows {
                if let tile = grid[col][row] { types.append(tile) }
            }
        }

        repeat {
            types.shuffle()
            var index = 0
            for col in 0..<columns {
                for row in 0..<rows {
                    grid[col][row] = types[index]
                    index += 1
                }
            }
        } while !findMatches().isEmpty || !hasPossibleMoves()

        var layout: [GridPosition: TileType] = [:]
        for col in 0..<columns {
            for row in 0..<rows {
                layout[GridPosition(col: col, row: row)] = grid[col][row]
            }
        }
        return layout
    }

    /// Current full layout (used when (re)building the scene).
    func currentLayout() -> [GridPosition: TileType] {
        var layout: [GridPosition: TileType] = [:]
        for col in 0..<columns {
            for row in 0..<rows {
                if let tile = grid[col][row] {
                    layout[GridPosition(col: col, row: row)] = tile
                }
            }
        }
        return layout
    }
}
